::HotSpringsWorldGenComponent <- class extends ::WorldComponent{
    mLogic_ = null;
    mIsActive_ = true;
    mParticleSystem_ = null;
    mLastDeliveryFactor_ = 0.0;

    constructor(world, logic, particleSystem = null){
        base.constructor(world);
        mLogic_ = logic;
        mParticleSystem_ = particleSystem;
    }

    function update(){
        if(!mIsActive_){
            return;
        }

        //When all health is delivered, disable the particle system
        if(mLogic_.mHealthToDeliver_ <= 0.001){
            mLogic_.mHealthToDeliver_ = 0;
            mIsActive_ = false;
            if(mParticleSystem_ != null){
                mParticleSystem_.setEmitting(false);
            }
            return;
        }

        local playerPos = mWorld_.getPlayerPosition();
        local isInWater = mWorld_.getIsWaterForPosition(playerPos);
        if(isInWater){
            //Check if player health is already full; if so, skip delivery processing
            local entityManager = mWorld_.getEntityManager();
            local playerEID = mWorld_.getPlayerEID();
            local healthComponent = entityManager.getComponent(playerEID, EntityComponents.HEALTH);
            if(healthComponent != null && healthComponent.mHealth >= healthComponent.mMaxHealth){
                mLogic_.mElapsedTime_ = 0;
                return;
            }

            mLogic_.mElapsedTime_ += (1.0 / 60.0);

            //Calculate health delivery on a curve
            //Slow for first 2 seconds, speeds up, then becomes inactive
            local mDeliveryDuration_ = 8.0;
            local t = ::clampValue(mLogic_.mElapsedTime_ / mDeliveryDuration_, 0.0, 1.0);
            local deliveryFactor;

            if(t < 0.5){
                //First 4 seconds (50% of 8s): slow delivery, easing in
                deliveryFactor = ::Easing.easeInCubic(t / 0.5) * 0.5;
            } else if(t < 1.0){
                //Remaining 4 seconds: speed up with ease out
                deliveryFactor = 0.5 + ::Easing.easeOutCubic((t - 0.5) / 0.5) * 0.5;
            } else {
                deliveryFactor = 1.0;
            }

            //Calculate health delivered this frame based on the difference in delivery factor
            //Use total health for calculation so it's not affected by remaining health changes
            //Track cumulative integer health to avoid float accumulation in entity state
            local totalDelivered = (deliveryFactor * mLogic_.mTotalHealth_).tointeger();
            local lastDelivered = (mLastDeliveryFactor_ * mLogic_.mTotalHealth_).tointeger();
            mLastDeliveryFactor_ = deliveryFactor;

            local healthToApplyThisFrame = totalDelivered - lastDelivered;
            if(healthToApplyThisFrame > 0){
                local entityManager = mWorld_.getEntityManager();
                ::_applyHealthChangeOther(entityManager, mWorld_.getPlayerEID(), healthToApplyThisFrame);
                mLogic_.mHealthToDeliver_ -= healthToApplyThisFrame;
            }
        }
    }
};

::HouseEntryWalkComponent <- class extends ::WorldComponent{
    mAnimationProgress_ = 0.0;
    mStartPos_ = null;
    mEndPos_ = null;
    mComponentId_ = null;

    constructor(world, playerPos){
        base.constructor(world);
        mEndPos_ = playerPos.copy();
        mStartPos_ = playerPos.copy();
        mStartPos_.z = mStartPos_.z + 5;
        //Move player to the start of the walk animation
        mWorld_.mPlayerEntry_.setPosition(mStartPos_);
        mWorld_.mDisableLeaveCheck_ = true;
        //Exempt player walk animations from the gameplay pause mask so they
        //play during the logic-paused entry sequence
        mWorld_.mPlayerEntry_.getModel().setDefaultPauseMask(0x0);
    }

    function advanceWalkFrame_(){
        mAnimationProgress_ += 0.01;
        if(mAnimationProgress_ > 1.0) mAnimationProgress_ = 1.0;

        local a = ::Easing.easeOutCubic(mAnimationProgress_);
        local targetPos = ::calculateSimpleAnimation(mStartPos_, mEndPos_, a);
        local delta = targetPos - mWorld_.mPlayerEntry_.mPos_;
        mWorld_.mPlayerEntry_.move(delta);

        local remaining = 1.0 - mAnimationProgress_;
        mWorld_.mPlayerEntry_.setWalkAnimSpeed(remaining * remaining);

        if(mAnimationProgress_ >= 1.0){
            mWorld_.mDisableLeaveCheck_ = false;
            mWorld_.mPlayerEntry_.getModel().setDefaultPauseMask(null);
            local model = mWorld_.mPlayerEntry_.getModel();
            model.stopAnimationBaseType(CharacterModelAnimBaseType.UPPER_WALK);
            model.stopAnimationBaseType(CharacterModelAnimBaseType.LOWER_WALK);
            mWorld_.unregisterWorldComponent(mComponentId_);
        }
    }

    function update(){ advanceWalkFrame_(); }
    function updateLogicPaused(){ advanceWalkFrame_(); }

    function destroy(){
        mWorld_.mDisableLeaveCheck_ = false;
        mWorld_.mPlayerEntry_.getModel().setDefaultPauseMask(null);
        local model = mWorld_.mPlayerEntry_.getModel();
        model.stopAnimationBaseType(CharacterModelAnimBaseType.UPPER_WALK);
        model.stopAnimationBaseType(CharacterModelAnimBaseType.LOWER_WALK);
        //Snap to end position if destroyed early
        mWorld_.mPlayerEntry_.setPosition(mEndPos_);
    }
};

::HouseEntryAnimationComponent <- class extends ::WorldComponent{
    mAnimationProgress_ = 0.0;
    mComponentId_ = null;

    constructor(world){
        base.constructor(world);
        mWorld_.setLogicPaused(true);
    }

    function updateLogicPaused(){
        mAnimationProgress_ += 0.01;

        if(mAnimationProgress_ > 1.0){
            //Animation complete, restore normal camera and resume
            mWorld_.setLogicPaused(false);
            mWorld_.updateCameraPosition();
            mWorld_.unregisterWorldComponent(mComponentId_);
            return;
        }

        //Follow the player's current position as they walk (not a fixed starting position)
        local playerPos = mWorld_.getPlayerPosition();
        local zPos = mWorld_.getZForPos(playerPos);

        //Start position: higher up and offset, looking down at the player
        local startPos = playerPos.copy();
        startPos.y = zPos + 40;
        startPos.x -= 15;
        startPos.z += 15;
        local startLookAt = Vec3(playerPos.x, zPos, playerPos.z);

        //End position: normal camera state using the same maths as updateCameraPosition
        local zoom = mWorld_.mCurrentZoomLevel_;
        local xOff = cos(mWorld_.mRotation_.x) * zoom;
        local yOff = sin(mWorld_.mRotation_.x) * zoom;
        local rot = Vec3(xOff, 0, yOff);
        yOff = sin(mWorld_.mRotation_.y) * zoom;
        rot += Vec3(0, yOff, 0);
        local endPos = Vec3(playerPos.x, zPos, playerPos.z) + rot;
        local endLookAt = Vec3(playerPos.x, zPos, playerPos.z);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local a = ::Easing.easeOutCubic(mAnimationProgress_);
        local currentPos = ::calculateSimpleAnimation(startPos, endPos, a);
        local currentLookAt = ::calculateSimpleAnimation(startLookAt, endLookAt, a);

        parentNode.setPosition(currentPos);
        camera.lookAt(currentLookAt);
        _gameCore.update(currentLookAt);
    }

    function destroy(){
        //Ensure logic resumes if component is destroyed early
        if(mWorld_.mLogicPaused_){
            mWorld_.setLogicPaused(false);
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
            mAnimProgress_ += 0.3;
            if(mAnimProgress_ > 1.0) mAnimProgress_ = 1.0;

            mCurrentAngle_ = ::calculateSimpleAnimation(0.0, mTargetAngle_, mAnimProgress_);
            local quat = Quat(mCurrentAngle_, mRotationAxis_);
            entityNode.setOrientation(quat);
        }
    }

    function destroy(){
        //Orientation restoration is handled by DialogFacePlayerRestoreComponent
    }
};

::DialogFacePlayerRestoreComponent <- class extends ::WorldComponent{
    mEntityId_ = null;
    mComponentId_ = null;
    mStartingOrientation_ = null;
    mTargetAngle_ = null;
    mRotationAxis_ = null;
    mAnimProgress_ = 0.0;

    constructor(world, entityId, startingOrientation, targetAngle, rotationAxis){
        base.constructor(world);
        mEntityId_ = entityId;
        mStartingOrientation_ = startingOrientation;
        mTargetAngle_ = targetAngle;
        mRotationAxis_ = rotationAxis;
    }

    function updateLogicPaused(){
        local manager = mWorld_.getEntityManager();
        if(!manager.entityValid(mEntityId_)) return;
        if(!manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)) return;

        mAnimProgress_ += 0.3;
        if(mAnimProgress_ > 1.0) mAnimProgress_ = 1.0;

        local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);

        if(mTargetAngle_ != null && mRotationAxis_ != null){
            local a = ::Easing.easeOutCubic(mAnimProgress_);
            local currentAngle = ::calculateSimpleAnimation(mTargetAngle_, 0.0, a);
            local quat = Quat(currentAngle, mRotationAxis_);
            comp.mNode.setOrientation(quat);
        }

        if(mAnimProgress_ >= 1.0){
            if(mStartingOrientation_ != null){
                comp.mNode.setOrientation(mStartingOrientation_);
            }
            mWorld_.unregisterWorldComponent(mComponentId_);
        }
    }

    function destroy(){
        //Restore original orientation if component is destroyed early
        local manager = mWorld_.getEntityManager();
        if(manager.entityValid(mEntityId_) && manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)){
            local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);
            if(mStartingOrientation_ != null){
                comp.mNode.setOrientation(mStartingOrientation_);
            }
        }
    }
};

::DialogCameraZoomComponent <- class extends ::WorldComponent{
    mEntityId_ = null;
    mAnimProgress_ = 0.0;
    mStartCamPos_ = null;
    mStartLookAt_ = null;
    mTargetCamPos_ = null;
    mTargetLookAt_ = null;

    constructor(world, entityId, startCamPos, startLookAt){
        base.constructor(world);
        mEntityId_ = entityId;
        mStartCamPos_ = startCamPos;
        mStartLookAt_ = startLookAt;
    }

    function updateLogicPaused(){
        //print("hello")
        if(mStartCamPos_ == null) return;

        local manager = mWorld_.getEntityManager();
        if(!manager.entityValid(mEntityId_)) return;
        if(!manager.hasComponent(mEntityId_, EntityComponents.SCENE_NODE)) return;

        //Calculate and cache the target camera state on the first frame
        if(mTargetCamPos_ == null){
            local comp = manager.getComponent(mEntityId_, EntityComponents.SCENE_NODE);
            local entityNode = comp.mNode;
            local entityPos = entityNode.getPositionVec3();
            local playerPos = mWorld_.getPlayerPosition();

            //Get entity height from AABB, fall back to a sensible default
            local entityHeight = 8.0;
            local aabb = mWorld_.getEntityAABB(mEntityId_);
            local aabbSize = aabb.getSize();
            if(aabbSize.y > 0.1){
                entityHeight = aabbSize.y;
            }

            //Direction from player to NPC (XZ only)
            local dir = Vec3(entityPos.x - playerPos.x, 0.0, entityPos.z - playerPos.z);
            local separation = dir.length();
            dir.normalise();

            //Perpendicular axis to the player-NPC line
            local perp = Vec3(-dir.z, 0.0, dir.x);

            //Midpoint between the two characters as the look-at anchor
            local midX = (playerPos.x + entityPos.x) * 0.5;
            local midZ = (playerPos.z + entityPos.z) * 0.5;
            local midY = entityPos.y + entityHeight * 0.3;
            local midPoint = Vec3(midX, midY, midZ);

            //Camera stand-off: far enough to frame both characters
            local distance = separation * 0.8;
            if(entityHeight * 2.0 > distance){ distance = entityHeight * 2.0; }
            //Higher camera looking down at the characters
            local heightOffset = entityHeight * 1.8;

            //Slight forward angle towards the NPC (blend perpendicular with forward direction)
            local angleBlend = 0.3;
            local blendedDir = perp + (dir * angleBlend);
            blendedDir.normalise();

            //Pick whichever side keeps the camera closest to where it already is
            local candA = Vec3(midX + blendedDir.x * distance, midPoint.y + heightOffset, midZ + blendedDir.z * distance);
            local candB = Vec3(midX - blendedDir.x * distance, midPoint.y + heightOffset, midZ - blendedDir.z * distance);
            local diffA = mStartCamPos_ - candA;
            local diffB = mStartCamPos_ - candB;
            mTargetCamPos_ = (diffA.length() <= diffB.length()) ? candA : candB;
            mTargetLookAt_ = midPoint;
        }

        if(mAnimProgress_ < 1.0){
            mAnimProgress_ += 0.03;
            if(mAnimProgress_ > 1.0) mAnimProgress_ = 1.0;
        }

        local a = ::Easing.easeOutCubic(mAnimProgress_);
        local currentPos = ::calculateSimpleAnimation(mStartCamPos_, mTargetCamPos_, a);
        local currentLookAt = ::calculateSimpleAnimation(mStartLookAt_, mTargetLookAt_, a);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        if(camera == null) return;
        camera.getParentNode().setPosition(currentPos);
        camera.lookAt(currentLookAt);
    }

    function destroy(){}
};

::DialogCameraZoomRestoreComponent <- class extends ::WorldComponent{
    mComponentId_ = null;
    mAnimProgress_ = 0.0;
    mStartCamPos_ = null;
    mStartLookAt_ = null;
    mTargetCamPos_ = null;
    mTargetLookAt_ = null;

    constructor(world, startCamPos, startLookAt){
        base.constructor(world);
        mStartCamPos_ = startCamPos;
        mStartLookAt_ = startLookAt;
    }

    function updateLogicPaused(){
        if(mStartCamPos_ == null) return;

        //Calculate the target (normal camera state) on the first frame
        if(mTargetCamPos_ == null){
            local endZoom = mWorld_.mCurrentZoomLevel_;
            local playerPos = mWorld_.getPlayerPosition();
            local endZPos = mWorld_.getZForPos(playerPos);
            local cameraData = mWorld_.calculateCameraPositionAndLookAt(playerPos, endZPos, endZoom);
            mTargetCamPos_ = cameraData[0];
            mTargetLookAt_ = cameraData[1];
        }

        mAnimProgress_ += 0.03;
        if(mAnimProgress_ > 1.0) mAnimProgress_ = 1.0;

        local a = ::Easing.easeOutCubic(mAnimProgress_);
        local currentPos = ::calculateSimpleAnimation(mStartCamPos_, mTargetCamPos_, a);
        local currentLookAt = ::calculateSimpleAnimation(mStartLookAt_, mTargetLookAt_, a);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
        if(camera == null) return;
        camera.getParentNode().setPosition(currentPos);
        camera.lookAt(currentLookAt);

        if(mAnimProgress_ >= 1.0){
            mWorld_.setLogicPaused(false);
            mWorld_.unregisterWorldComponent(mComponentId_);
        }
    }

    function destroy(){
        //Ensure logic is resumed if the component is destroyed early
        if(mWorld_.mLogicPaused_){
            mWorld_.setLogicPaused(false);
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