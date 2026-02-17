::HotSpringsWorldGenComponent <- class extends ::WorldComponent{
    waterCount = 0;
    function update(){
        local playerPos = mWorld_.getPlayerPosition();
        local isInWater = mWorld_.getIsWaterForPosition(playerPos);
        if(isInWater){
            //print("in the hot spring");

            waterCount++;
            if(waterCount % 60 == 0){
                local entityManager = mWorld_.getEntityManager();
                ::_applyHealthChangeOther(entityManager, mWorld_.getPlayerEID(), 1);
            }

        }
    }
};

::StartupAnimationComponent <- class extends ::WorldComponent{
    mAnimationProgress_ = 0.0;
    mWorldCentre_ = null;
    mPlayerPos_ = null;
    mComponentId_ = null;

    constructor(world){
        base.constructor(world);
        mWorld_.setLogicPaused(true);
        //Calculate world centre from map data
        local mapData = mWorld_.getMapData();
        mWorldCentre_ = Vec3(mapData.width * 0.5, 0, -mapData.height * 0.5);
        mPlayerPos_ = mWorld_.getPlayerPosition();
    }

    function updateLogicPaused(){
        mAnimationProgress_ += 0.012;

        if(mAnimationProgress_ > 1.0){
            //Animation complete
            mWorld_.setLogicPaused(false);
            mWorld_.unregisterWorldComponent(mComponentId_);
            return;
        }

        //Start values
        local startPos = mPlayerPos_.copy();
        startPos.x = startPos.x - 60;
        startPos.z = startPos.z + 200;
        startPos.y += 200;
        local startLookAt = mPlayerPos_.copy();
        startLookAt.y = 0;

        //Calculate end state (normal zoom at player)
        local endZoom = mWorld_.mCurrentZoomLevel_;
        local endLookAt = mPlayerPos_;
        local endZPos = mWorld_.getZForPos(endLookAt);
        local cameraData = mWorld_.calculateCameraPositionAndLookAt(endLookAt, endZPos, endZoom);

        //Get the camera
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local a = ::Easing.easeOutCubic(mAnimationProgress_);
        //local a = 0;
        local currentCentre = ::calculateSimpleAnimation(startPos, cameraData[0], a);
        local currentLookAt = ::calculateSimpleAnimation(startLookAt, cameraData[1], a);

        parentNode.setPosition(currentCentre);
        camera.lookAt(currentLookAt);
        //_gameCore.update(currentLookAt);
    }

    function destroy(){
        //Ensure we resume logic if component is destroyed early
        if(mWorld_.mLogicPaused_){
            mWorld_.setLogicPaused(false);
        }
    }
};

::DialogFacePlayerComponent <- class extends ::WorldComponent{
    mEntityId_ = null;
    mStartingOrientation_ = null;
    mTargetAngle_ = null;
    mRotationAxis_ = null;
    mCurrentAngle_ = 0.0;
    mAnimProgress_ = 0.0;

    constructor(world, entityId){
        base.constructor(world);
        mEntityId_ = entityId;
        local manager = mWorld_.getEntityManager();
        if(manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)){
            local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);
            local node = comp.mNode;
            mStartingOrientation_ = node.getOrientation();
        }
    }

    function updateLogicPaused(){
        local manager = mWorld_.getEntityManager();
        if(!manager.entityValid(mEntityId_)) return;
        if(!manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)) return;
        if(mStartingOrientation_ == null) return;

        local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);
        local entityNode = comp.mNode;

        //Calculate and cache the target angle and axis on the first frame
        if(mTargetAngle_ == null){
            local playerPos = mWorld_.getPlayerPosition();
            local entityPos = entityNode.getPositionVec3();

            local dirToPlayer = playerPos - entityPos;
            dirToPlayer.y = 0;
            dirToPlayer.normalise();
            dirToPlayer = dirToPlayer * -1;

            local forward = Vec3(0, 0, -1);
            local axis = forward.cross(dirToPlayer);
            local dot = forward.dot(dirToPlayer);

            if(axis.length() < 0.001){
                if(dot > 0.0){
                    mTargetAngle_ = 0.0;
                    mRotationAxis_ = Vec3(0, 1, 0);
                }else{
                    mTargetAngle_ = PI;
                    mRotationAxis_ = Vec3(0, 1, 0);
                }
            }else{
                axis.normalise();
                mRotationAxis_ = axis;
                mTargetAngle_ = acos(dot);
            }
        }

        if(mAnimProgress_ < 1.0){
            mAnimProgress_ += 0.05;
            if(mAnimProgress_ > 1.0) mAnimProgress_ = 1.0;

            mCurrentAngle_ = ::calculateSimpleAnimation(0.0, mTargetAngle_, mAnimProgress_);
            local quat = Quat(mCurrentAngle_, mRotationAxis_);
            entityNode.setOrientation(quat);
        }
    }

    function destroy(){
        //Restore the original orientation
        local manager = mWorld_.getEntityManager();
        if(manager.entityValid(mEntityId_) && manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)){
            local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);
            if(mStartingOrientation_ != null){
                comp.mNode.setOrientation(mStartingOrientation_);
            }
        }
    }
};

//NOTE temporary
::DebugCameraSpinComponent <- class extends ::WorldComponent{
    mRotationCounter_ = 0.0;

    function updateLogicPaused(){
        mRotationCounter_ += 0.01;
        if(mRotationCounter_ >= 1000.0){
            mRotationCounter_ = 0.0;
        }

        local angle = mRotationCounter_ * 2 * PI;
        local radius = mWorld_.mCurrentZoomLevel_;

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local playerPos = mWorld_.getPlayerPosition();
        local zPos = mWorld_.getZForPos(playerPos);
        local xOffset = cos(angle) * radius;
        local zOffset = sin(angle) * radius;

        parentNode.setPosition(Vec3(playerPos.x + xOffset, zPos + 20, playerPos.z + zOffset));
        camera.lookAt(playerPos.x, zPos, playerPos.z);
    }
};