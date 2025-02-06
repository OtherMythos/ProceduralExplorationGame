::VisitedLocationWorld <- class extends ::World{

    mMapData_ = null;
    mTargetMap_ = null;
    mTerrainChunkManager_ = null;
    mSwimAllowed_ = true;
    mTileGridPlacer_ = null;
    mForceZPos_ = null;

    mPlayerStartPos_ = null;

    mCurrentWorldAnim_ = null;

    mCloudManager_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mPlayerStartPos_ = Vec3();

        mTerrainChunkManager_ = TerrainChunkManager(worldId);
        preparer.provideChunkManager(mTerrainChunkManager_);

        mTileGridPlacer_ = ::TileGridPlacer([
            "InteriorFloor.voxMesh", "InteriorWall.voxMesh", "InteriorWallCorner.voxMesh"
        ], 5);
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

    #Override
    function resetSession(mapData){
        base.resetSession();

        mMapData_ = mapData;

        if(mMapData_.meta.rawin("width")){
            mMapData_.width = mMapData_.meta.width;
        }
        if(mMapData_.meta.rawin("height")){
            mMapData_.height = mMapData_.meta.height;
        }

        if(mMapData_.meta.rawin("zPos")){
            mForceZPos_ = mMapData_.meta.zPos;
        }else{
            mForceZPos_ = null;
        }

        readMapMeta();
        createScene();
    }

    #Override
    function shutdown(){
        mCurrentWorldAnim_ = null;

        base.shutdown();
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

        if(mCloudManager_ != null) mCloudManager_.update();

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
        local y = mPlayerEntry_.getPosition().z.tointeger();
        if(x < 0 || y < 0 || x >= mMapData_.width || y >= mMapData_.height){
            print("Player left visited location");
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
        if(mForceZPos_ != null){
            return mForceZPos_;
        }

        if(mMapData_ == null) return 0;

        return mMapData_.native.getAltitudeForPos(pos) * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
    }

    #Override
    function getIsWaterForPosition(pos){
        if(!mSwimAllowed_) return false;
        return getZForPos(pos) == 0;
    }

    function readMapMeta(){
        if(mMapData_.meta.rawin("swimAllowed")){
            mSwimAllowed_ = mMapData_.meta.swimAllowed;
        }
    }

    function placeGrid_(){
        local tileArray = mMapData_.native.getTileArray();
        if(tileArray != null){
            local tileNode = mTileGridPlacer_.insertGridToScene(mParentNode_, tileArray, mMapData_.mapData.tilesWidth, mMapData_.mapData.tilesHeight);
            tileNode.setPosition(3, 0, 3);

            tileArray.apply(function(item){
                return (item & 0xF) != 0 ? true : 1;
            });
            _gameCore.setupCollisionDataForWorld(mCollisionDetectionWorld_, tileArray, mMapData_.mapData.tilesWidth, mMapData_.mapData.tilesHeight);
        }
    }

    function createScene(){
        local targetNode = mParentNode_.createChildSceneNode();
        local animData = null;
        if(mMapData_.parsedSceneFile != null){
            animData = _gameCore.insertParsedSceneFileGetAnimInfo(mMapData_.parsedSceneFile, targetNode, mCollisionDetectionWorld_);
        }
        if(animData != null){
            mCurrentWorldAnim_ = _animation.createAnimation("sceneAnim", animData);
        }

        local drawClouds = true;
        if(mMapData_.meta.rawin("clouds")){
            drawClouds = mMapData_.meta.clouds;
        }
        if(drawClouds){
            mCloudManager_ = CloudManager(mParentNode_, mMapData_.width, mMapData_.height);
        }

        //mTerrainChunkManager_.setup(targetNode, mMapData_.mapData, 4);
        mTerrainChunkManager_.setupParentNode(targetNode);

        local drawOcean = true;
        if(mMapData_.meta.rawin("ocean")){
            drawOcean = mMapData_.meta.ocean;
        }
        if(drawOcean){
            local oceanNode = mParentNode_.createChildSceneNode();
            local oceanItem = _scene.createItem("plane");
            oceanItem.setCastsShadows(false);
            oceanItem.setRenderQueueGroup(30);
            oceanItem.setDatablock("oceanUnlit");
            oceanNode.attachObject(oceanItem);
            oceanNode.setScale(500, 500, 500)
            oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
        }

        placeGrid_();

        //Parse data points
        local native = mMapData_.native;
        local data = array(2);
        for(local i = 0; i < native.getNumDataPoints(); i++){
            native.getDataPointAt(i, data);
            local val = data[1];
            local major = (val >> 16) & 0xFFFF;
            local minor = val & 0xFFFF;
            processDataPoint(data[0], major, minor);
        }

        local pos = Vec3(mPlayerStartPos_.x, 0, mPlayerStartPos_.z);
        pos.y = getZForPos(pos);
        mPlayerEntry_.setPosition(pos);
        notifyPlayerMoved();
    }

    function processDataPoint(pos, major, minor){
        switch(major){
            case 0:{
                processMetaDataPoint(pos, minor);
                break;
            }
            case 1:{
                mMapData_.scriptObject.setupForNPCDataPoint(this, pos, minor);
                break;
            }
        }
    }

    function processMetaDataPoint(pos, id){
        switch(id){
            case 0:{
                mPlayerStartPos_ = pos;
                break;
            }
        }
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