::Overworld <- class extends ::ProceduralExplorationWorld{

    mCameraPosition_ = null;
    mZoomAmount_ = 0.0;
    MAX_ZOOM = 200;

    mRegionPicker_ = null;
    mCurrentSelectedRegion_ = null;

    mTargetCameraPosition_ = null;

    mRegionAnimator_ = null;
    mRegionUnlockAnimData_ = null;

    mNodeData_ = null;

    OverworldRegionAnimator = class{
        mRegionUndiscoveredDatablocks_ = null;
        mRegionDiscoveredDatablocks_ = null;
        mRegionAnimationCount_ = null;

        mStartDiffuse_ = null;

        mPreviousSelectedRegion_ = null;

        mAnim_ = 0.0;

        constructor(){
            mRegionUndiscoveredDatablocks_ = {};
            mRegionDiscoveredDatablocks_ = {};
            mRegionAnimationCount_ = {};

            mStartDiffuse_ = _hlms.getDatablock("MaskedWorld").getDiffuse().copy();
        }

        function update(){
            local finishedRegions = null;

            foreach(c,i in mRegionAnimationCount_){
                local anim = ::accelerationClampCoordinate_(i, 1.0, 0.05);
                mRegionAnimationCount_[c] = anim;
                if(anim >= 1.0){
                    if(finishedRegions == null){
                        finishedRegions = [];
                    }
                    finishedRegions.append(c);
                }

                update_(anim, c);

            }

            if(finishedRegions != null){
                foreach(i in finishedRegions){
                    mRegionAnimationCount_.rawdelete(i);
                }
            }
        }

        function update_(anim, regionId){
            //Temporary
            return;
            local baseColour = calculateBaseDiffuse_(regionId);
            baseColour = mix(::Vec3_UNIT_SCALE, baseColour, anim);
            mRegionUndiscoveredDatablocks_[regionId].setDiffuse(baseColour.x, baseColour.y, baseColour.z);
        }

        function updateSelectedRegionAnim(regionId){
            if(mPreviousSelectedRegion_ != null && mPreviousSelectedRegion_ != regionId){
                local targetDiffuse = calculateBaseDiffuse_(regionId);
                mRegionUndiscoveredDatablocks_[mPreviousSelectedRegion_].
                    setDiffuse(targetDiffuse.x, targetDiffuse.y, targetDiffuse.z);
                mRegionDiscoveredDatablocks_[mPreviousSelectedRegion_].
                    setDiffuse(1, 1, 1);
                mPreviousSelectedRegion_ = null;
                mAnim_ = PI;
            }

            mPreviousSelectedRegion_ = regionId;

            local block = mRegionUndiscoveredDatablocks_[regionId];
            local startDiffuse = calculateBaseDiffuse_(regionId);
            local baseColour = mix(startDiffuse + (startDiffuse * 0.2), startDiffuse, sin(mAnim_));
            block.setDiffuse(baseColour.x, baseColour.y, baseColour.z);

            block = mRegionDiscoveredDatablocks_[regionId];
            baseColour = mix(Vec3(0.8, 0.8, 0.8), ::Vec3_UNIT_SCALE, sin(mAnim_));
            block.setDiffuse(baseColour.x, baseColour.y, baseColour.z);
            mAnim_ += 0.05;
        }

        function calculateBaseDiffuse_(id){
            return mStartDiffuse_;
            //return mix(::Vec3_UNIT_SCALE, mStartDiffuse_, 0.9 + ((id.tofloat() % 24) / 24) * 0.1);
        }

        function shutdown(){
            foreach(c,i in mRegionUndiscoveredDatablocks_){
                _hlms.destroyDatablock(i);
            }
            foreach(c,i in mRegionDiscoveredDatablocks_){
                _hlms.destroyDatablock(i);
            }
            mRegionUndiscoveredDatablocks_.clear();
            mRegionDiscoveredDatablocks_.clear();
        }

        function createDatablockForRegion(c){
            local first = ::DatablockManager.quickCloneDatablock("baseVoxelMaterial");
            mRegionDiscoveredDatablocks_.rawset(c, first);

            local second = ::DatablockManager.quickCloneDatablock("MaskedWorld");
            mRegionUndiscoveredDatablocks_.rawset(c, second);

            //Use the id rather than a random number so you always get the same colour.
            local col = calculateBaseDiffuse_(c);
            second.setDiffuse(col.x, col.y, col.z);
        }

        function getDatablockForRegion(region, discovered){
            if(discovered){
                return mRegionDiscoveredDatablocks_[region];
            }else{
                return mRegionUndiscoveredDatablocks_[region];
            }
        }

        function notifyRegionJustHighlighted(id){
            mRegionAnimationCount_.rawset(id, 0.0);
        }
    };

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mRegionAnimator_ = OverworldRegionAnimator();
    }

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

        mNodeData_ = _gameCore.insertParsedSceneFileGetAnimInfoOverworld(parsedFile, mParentNode_);

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

        mRegionAnimator_.shutdown();
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

            mRegionAnimator_.createDatablockForRegion(c);

            local terrainRenderQueue = RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED;
            local terrainDatablock = null;
            local sceneObjectsVisible = true;
            if(discoveryCount == 0){
                sceneObjectsVisible = false;
                terrainRenderQueue = RENDER_QUEUE_EXPLORATION_TERRRAIN_UNDISCOVERED;
            }
            terrainDatablock = mRegionAnimator_.getDatablockForRegion(c, discoveryCount != 0);

            local e = mRegionEntries_[c];
            if(e.mLandItem_){
                e.mLandItem_.setRenderQueueGroup(terrainRenderQueue);
                e.mLandItem_.setDatablock(terrainDatablock);
            }

            local testId = c.tostring();
            if(mNodeData_.rawin(testId)){
                mNodeData_[testId].setVisible(sceneObjectsVisible);
            }
        }

        mRegionPicker_ = mParentNode_.createChildSceneNode();
        mRegionPicker_.attachObject(_scene.createItem("cube"));
        mRegionPicker_.setScale(1, 10, 1);
        mRegionPicker_.setVisible(false);
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

        mRegionAnimator_.update();
        if(mCurrentSelectedRegion_ != null){
            mRegionAnimator_.updateSelectedRegionAnim(mCurrentSelectedRegion_);
        }

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

        mRegionAnimator_.notifyRegionJustHighlighted(region);

        _event.transmit(Event.OVERWORLD_SELECTED_REGION_CHANGED, {"id": region, "data": regionEntry});
    }

    function setOverworldSelectionActive(active){
        mRegionPicker_.setVisible(active);
    }

    function getCurrentSelectedRegion(){
        return mCurrentSelectedRegion_;
    }

    function getAABBForRegion(regionId){
        return mRegionEntries_[regionId].calculateAABB();
    }

    function animateRegionDiscovery(regionId){
        local regionEntry = mRegionEntries_[regionId]
        if(regionEntry != null){
            regionEntry.mWorldActive_ = true;
            regionEntry.setVisible(true);
            regionEntry.performArrival();
        }
    }

    function updateRegionDiscoveryAnimation(regionId, anim){
        local regionEntry = mRegionEntries_[regionId]
        if(regionEntry == null) return;

        local node = regionEntry.mLandNode_;
        local item = regionEntry.mLandItem_;

        if(mRegionUnlockAnimData_ == null){
            local block = mRegionAnimator_.getDatablockForRegion(regionId, false);
            mRegionUnlockAnimData_ = {
                "startPos": node.getPositionVec3(),
                "startDiffuse": block.getDiffuse(),
                "stage": 0
            };
        }

        if(anim <= 0.8){
            local block = mRegionAnimator_.getDatablockForRegion(regionId, false);

            local aa = anim / 0.8;
            local a = ::Easing.easeInOutQuad(aa);
            local colAnim = 0.3 + 2 * a;
            block.setDiffuse(colAnim, colAnim, colAnim);

            local mov = _random.randVec3();
            node.setPosition(mRegionUnlockAnimData_.startPos + (mov * a * 0.6));
            _scene.notifyStaticDirty(node);

        }
        else if(anim >= 0.8 && anim <= 1.0){
            if(mRegionUnlockAnimData_.stage == 0){
                mRegionUnlockAnimData_.stage++;
            }
            local block = mRegionAnimator_.getDatablockForRegion(regionId, true);
            item.setDatablock(block);
            item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED);

            node.setPosition(mRegionUnlockAnimData_.startPos);
            _scene.notifyStaticDirty(node);

            local targetId = mCurrentSelectedRegion_.tostring();
            if(mNodeData_.rawin(targetId)){
                local targetNode = mNodeData_.rawget(targetId);
                targetNode.setVisible(true);
            }
        }

        if(anim == 1.0){
            mRegionUnlockAnimData_ = null;
        }
    }

    function getCameraPosition(){
        return mCameraPosition_;
    }

    function getTargetCameraPosition(){
        return mTargetCameraPosition_;
    }
};