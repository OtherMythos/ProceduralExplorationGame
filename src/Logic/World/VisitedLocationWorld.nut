::VisitedLocationWorld <- class extends ::World{

    mMapData_ = null;
    mTargetMap_ = null;
    mVoxTerrainMesh_ = null;
    mTerrainChunkManager_ = null;

    mCloudManager_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mTerrainChunkManager_ = TerrainChunkManager(worldId);
        preparer.provideChunkManager(mTerrainChunkManager_)
    }

    #Override
    function getWorldType(){
        return WorldTypes.VISITED_LOCATION_WORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Visited Location";
    }

    #Override
    function notifyPreparationComplete_(){
        mReady_ = true;
        base.setup();
        resetSession(mWorldPreparer_.getOutputData());
    }

    function resetSession(mapData){
        base.resetSession();

        mMapData_ = mapData;

        createScene();
    }

    #Override
    function processWorldActiveChange_(active){
        if(mMapData_.scriptObject != null){
            mMapData_.scriptObject.worldActiveChange(this, active);
        }
    }
    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
    }

    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();
    }

    function update(){
        if(!isActive()) return;

        base.update();

        mCloudManager_.update();

        if(mMapData_.scriptObject != null){
            mMapData_.scriptObject.update(this);
        }

        checkIfPlayerHasLeft();
    }

    function updateCameraPosition(){
        local zPos = getZForPos(mPosition_);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local xPos = cos(mRotation_.x)*mCurrentZoomLevel_;
        local yPos = sin(mRotation_.x)*mCurrentZoomLevel_;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*mCurrentZoomLevel_;
        rot += Vec3(0, yPos, 0);

        parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        camera.lookAt(mPosition_.x, zPos, mPosition_.z);
    }

    function checkIfPlayerHasLeft(){
        local x = mPlayerEntry_.getPosition().x.tointeger();
        local y = -mPlayerEntry_.getPosition().z.tointeger();
        if(x < 0 || y < 0 || x >= mMapData_.width || y >= mMapData_.height){
            ::Base.mExplorationLogic.popWorld();
        }
    }

    function processCameraMove(x, y){
        mRotation_ += Vec2(x, y) * -0.05;
        local first = PI * 0.5;
        local second = PI * 0.1;
        if(mRotation_.y > first) mRotation_.y = first;
        if(mRotation_.y < second) mRotation_.y = second;

        local mouseScroll = _input.getMouseWheelValue();
        if(mouseScroll != 0){
            mCurrentZoomLevel_ += mouseScroll;
            if(mCurrentZoomLevel_ < MIN_ZOOM) mCurrentZoomLevel_ = MIN_ZOOM;
        }

        updateCameraPosition();
    }

    #Override
    function getZForPos(pos){
        if(mMapData_ == null) return 0;

        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        if(x < 0 || y < 0 || x >= mMapData_.width || y >= mMapData_.height) return 0;

        local height = mMapData_.mapData.voxHeight.data[x + y * mMapData_.width];

        return height * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
    }

    #Override
    function getIsWaterForPosition(pos){
        return getZForPos(pos) == 0;
    }

    function createScene(){
        local targetNode = mParentNode_.createChildSceneNode();
        local animData = null;
        if(mMapData_.parsedSceneFile != null){
            animData = _scene.insertParsedSceneFileGetAnimInfo(mMapData_.parsedSceneFile, targetNode);
        }
        if(animData != null){
            ::currentAnim <- _animation.createAnimation("sceneAnim", animData);
        }

        mCloudManager_ = CloudManager(mParentNode_, mMapData_.width, mMapData_.height);

        //mTerrainChunkManager_.setup(targetNode, mMapData_.mapData, 4);
        mTerrainChunkManager_.setupParentNode(targetNode);

        local oceanNode = mParentNode_.createChildSceneNode();
        local oceanItem = _scene.createItem("plane");
        oceanItem.setCastsShadows(false);
        oceanItem.setRenderQueueGroup(30);
        oceanItem.setDatablock("oceanUnlit");
        oceanNode.attachObject(oceanItem);
        oceanNode.setScale(500, 500, 500)
        oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        //local character = mEntityFactory_.constructNPCCharacter();
        //mActiveEnemies_.rawset(character.mEntity_.getId(), character);
        //character.moveQueryZ(Vec3(100, 0, -50));
    }

    function getMapData(){
        return mMapData_;
    }

    #Override
    function checkForEnemyAppear(){
        //Stub to get enemies to stop spawning.
        return;
    }
    #Override
    function checkForDistractionAppear(){
        //Stub
        return
    }

};