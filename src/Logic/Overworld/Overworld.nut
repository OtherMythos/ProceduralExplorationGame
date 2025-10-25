::Overworld <- class extends ::ProceduralExplorationWorld{

    mCameraPosition_ = null;
    mZoomAmount_ = 0.0;
    MAX_ZOOM = 200;

    mRegionPicker_ = null;
    mCurrentSelectedRegion_ = null;

    mTargetCameraPosition_ = null;

    #Override
    function setup(){
        base.setup();

        local mapsDir = ::BaseHelperFunctions.getOverworldDir();

        local targetMap = "overworld";
        local path = mapsDir + targetMap + "/scene.avScene";
        local parsedFile = null;
        if(_system.exists(path)){
            printf("Loading scene file with path '%s'", path);
            parsedFile = _scene.parseSceneFile(path);
        }

        local animData = _gameCore.insertParsedSceneFileGetAnimInfo(parsedFile, mParentNode_, mCollisionDetectionWorld_);

        mCameraPosition_ = getOverworldStartPosition();
        mTargetCameraPosition_ = getOverworldStartPosition();

        setFogStartEnd(1000, 10000);
        setBackgroundColour(getDefaultSkyColour());
        setBiomeAmbientModifier(getDefaultAmbientModifier());
        setBiomeLightModifier(getDefaultLightModifier());
    }

    #Override
    function shutdown(){
        base.shutdown();

        ::Base.mPlayerStats.setOverworldStartPosition(mCameraPosition_);
    }

    #Override
    function getWorldType(){
        return WorldTypes.OVERWORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Overworld";
    }

    #Override
    function notifyPlayerMoved(){

    }

    #Override
    function getWaterDatablock_(name, outside=false){
        local block = base.getWaterDatablock_(name, outside);
        block.setTexture(_PBSM_DIFFUSE, "blueTexture");
        block.setTexture(_PBSM_DETAIL_WEIGHT, null);
        return block;
    }

    function getOverworldStartPosition(){
        local startPosition = ::Base.mPlayerStats.getOverworldStartPosition();
        if(startPosition != null){
            return startPosition;
        }
        return getDefaultOverworldStartPosition();
    }

    function getDefaultOverworldStartPosition(){
        return Vec3(476.48, 0, -113.84);
    }

    #Override
    function getWaterPlaneMesh(){
        return "simpleWaterPlaneMesh";
    }
    #Override
    function getSurroundingWaterPlaneMesh(){
        return getWaterPlaneMesh();
    }

    #Override
    function constructPlayerEntry_(){

    }

    #Override
    function resetSession(mapData, nativeMapData){
        base.resetSession(mapData, nativeMapData);

        foreach(c,i in mRegionEntries_){
            local discoveryCount = ::Base.mPlayerStats.getRegionIdDiscovery(c);

            local terrainRenderQueue = RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED;
            if(discoveryCount == 0){
                terrainRenderQueue = RENDER_QUEUE_EXPLORATION_TERRRAIN_UNDISCOVERED;
            }

            local e = mRegionEntries_[c];
            if(e.mLandItem_){
                e.mLandItem_.setRenderQueueGroup(terrainRenderQueue);
            }
        }

        mRegionPicker_ = mParentNode_.createChildSceneNode();
        mRegionPicker_.attachObject(_scene.createItem("cube"));
        mRegionPicker_.setScale(1, 10, 1);
    }

    function applyMovementDelta(delta){
        mCameraPosition_ += (Vec3(delta.x, 0, delta.y) * 0.1);
        updateCameraPosition();
    }

    function applyZoomDelta(delta){
        mZoomAmount_ += delta;
        if(mZoomAmount_ < 0.0) mZoomAmount_ = 0.0;
        if(mZoomAmount_ >= MAX_ZOOM) mZoomAmount_ = MAX_ZOOM;
    }

    #Override
    function processCameraMove(x, y){

    }

    function update(){
        mCloudManager_.update();
        mWindStreakManager_.update();

        _gameCore.update(mCameraPosition_);
        _gameCore.setCustomPassBufferValue(0, 0, 0);

        foreach(c,i in mRegionEntries_){
            i.update();
        }

        mAnimIncrement_ += 0.01;
        updateWaterBlock(mWaterDatablock_);
        updateWaterBlock(mOutsideWaterDatablock_);
    }

    #Override
    function getTerrainRenderQueueStart(){
        return RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED;
    }

    #Override
    function isActive(){
        return true;
    }

    function updateCameraPosition(){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local xPos = cos(mRotation_.x)*mCurrentZoomLevel_;
        local yPos = sin(mRotation_.x)*mCurrentZoomLevel_;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*mCurrentZoomLevel_;
        rot += Vec3(0, yPos, 0);

        //parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        local zoom = Vec3(0, 50 + mZoomAmount_, 50 + mZoomAmount_);
        mTargetCameraPosition_ = (mCameraPosition_ + zoom);
        //parentNode.setPosition(mCameraPosition_ + zoom);
        //camera.lookAt(mCameraPosition_);

        mRegionPicker_.setPosition(mCameraPosition_);
        updateSelectedRegion_();
    }

    function updateSelectedRegion_(){
        local region = ::currentNativeMapData.getRegionForPos(mCameraPosition_);
        local altitude = ::currentNativeMapData.getAltitudeForPos(mCameraPosition_);

        if(altitude < 100){
            if(mCurrentSelectedRegion_ != null){
                _event.transmit(Event.OVERWORLD_SELECTED_REGION_CHANGED, {"id": 0, "data": null});
            }
            mCurrentSelectedRegion_ = null;
            return;
        }

        if(region == mCurrentSelectedRegion_){
            return;
        }
        mCurrentSelectedRegion_ = region;

        local regionMeta = ::OverworldLogic.mOverworldRegionMeta_;
        local checkRegion = region.tostring();

        local regionEntry = null;
        if(regionMeta.rawin(checkRegion)){
            regionEntry = ::OverworldLogic.mOverworldRegionMeta_[region.tostring()];
        }

        _event.transmit(Event.OVERWORLD_SELECTED_REGION_CHANGED, {"id": region, "data": regionEntry});
    }

    function getCurrentSelectedRegion(){
        return mCurrentSelectedRegion_;
    }

    function animateRegionDiscovery(regionId){
        local regionEntry = mRegionEntries_[regionId]
        if(regionEntry != null){
            regionEntry.mWorldActive_ = true;
            regionEntry.setVisible(true);
            regionEntry.performArrival();
        }
    }

    function getCameraPosition(){
        return mCameraPosition_;
    }

    function getTargetCameraPosition(){
        return mTargetCameraPosition_;
    }
};