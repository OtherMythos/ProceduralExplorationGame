::ProceduralExplorationWorld <- class extends ::World{
    mMapData_ = null;

    static WORLD_DEPTH = 20;
    ABOVE_GROUND = null;
    mVoxMesh_ = null;
    mWorldViewActive_ = false;
    mWorldViewAnim_ = 1.0;

    mActivePlaces_ = null;
    mCurrentFoundRegions_ = null;
    mRegionEntries_ = null;

    mAnimIncrement_ = 0.0;
    mWaterDatablock_ = null;
    mOutsideWaterDatablock_ = null;

    mCloudManager_ = null;
    mWindStreakManager_ = null;

    WORLD_VIEW_DISTANCE = 300;

    mTerrain_ = null;

    ProceduralRegionEntry = class{
        mCreatorWorld_ = null;
        mEntityManager_ = null;
        mLandNode_ = null;
        mLandItem_ = null;
        mDecoratioNode_ = null;
        mVisible_ = false;
        mWorldActive_ = false;

        //TODO consider tying this into a class.
        mPlaceIds_ = null;
        mPlaces_ = null;
        mBeacons_ = null;

        mAnimCount_ = -1;
        mMaxAnim_ = 30;

        constructor(world, entityManager, node, decorationNode){
            mCreatorWorld_ = world;
            mEntityManager_ = entityManager;
            mLandNode_ = node;
            mDecoratioNode_ = decorationNode;
            if(mLandNode_){
                mLandItem_ = mLandNode_.getAttachedObject(0);
            }
            mPlaceIds_ = [];
            mPlaces_ = [];
            mBeacons_ = [];
        }
        function update(){
            if(mAnimCount_ <= 0) return;
            local animIdx = mAnimCount_.tofloat() / mMaxAnim_.tofloat();
            mAnimCount_--;
            local animPos = mAnimCount_ * -0.10;
            mLandNode_.setPosition(0, animPos, 0);
            mDecoratioNode_.setPosition(0, animPos, 0);
            _scene.notifyStaticDirty(mLandNode_);
            _scene.notifyStaticDirty(mDecoratioNode_);
        }
        function performArrival(){
            setVisible(true);
            mAnimCount_ = mMaxAnim_;
        }
        function setVisible(visible){
            mVisible_ = visible;
            setVisible_();
        }
        function setWorldActive(active){
            mWorldActive_ = active;
            setVisible_();
        }
        //Workaround to resolve the recursive setVisible from the world.
        function setVisible_(){
            local vis = mWorldActive_ && mVisible_;
            if(mLandNode_){
                mLandItem_.setDatablock(vis ? "baseVoxelMaterial" : "MaskedWorld");
                mLandItem_.setRenderQueueGroup(vis ?
                    RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED :
                    RENDER_QUEUE_EXPLORATION_TERRRAIN_UNDISCOVERED
                );
            }

            if(vis){
                for(local i = 0; i < mPlaceIds_.len(); i++){
                    //Perform the spawn functions for the specific place
                    local placeData = mPlaceIds_[i];
                    local placeDef = ::Places[placeData[0]];

                    local placeFileName = placeDef.getPlaceFileName();
                    assert(placeFileName != null);

                    //TODO nasty duplication
                    local scriptPath = "res://build/assets/places/" + placeFileName + "/script.nut";
                    if(_system.exists(scriptPath)){
                        _doFile(scriptPath);
                        if(::PlaceScriptObject.rawin("appear")){

                            local dataFile = null;
                            local dataPointPath = "res://build/assets/places/" + placeFileName + "/dataPoints.txt";
                            if(_system.exists(dataPointPath)){
                                local dataPoints = _gameCore.DataPointFile();
                                dataPoints.readFile(dataPointPath);

                                local data = array(2);
                                for(local i = 0; i < dataPoints.getNumDataPoints(); i++){
                                    dataPoints.getDataPointAt(i, data);
                                    local val = data[1];
                                    local major = (val >> 16) & 0xFFFF;
                                    local minor = val & 0xFFFF;


                                    if(::PlaceScriptObject.rawin("processDataPointBecameVisible")){
                                        ::PlaceScriptObject.processDataPointBecameVisible(mCreatorWorld_, placeData[1] + data[0] - placeDef.mCentre, major, minor, mDecoratioNode_);
                                    }
                                }
                            }

                            ::PlaceScriptObject.appear(mCreatorWorld_, placeData[0], placeData[1], mDecoratioNode_);
                        }
                    }
                }
            }

            foreach(i in mPlaces_){
                //TODO this will be massively inefficient so improve that
                i.getSceneNode().setVisible(vis);
            }
            /*
            foreach(i in mBeacons_){
                local node = mEntityManager_.getComponent(i, EntityComponents.SCENE_NODE).mNode;
                node.setVisible(mWorldActive_ && !mVisible_);
            }
            */
            mDecoratioNode_.setVisible(vis);
        }
        function pushPlace(place, beacon){
            mPlaces_.append(place);
            mBeacons_.append(beacon);
        }
        function pushFuncPlace(placeId, pos){
            mPlaceIds_.append([placeId, pos]);

            processPlaceCreation(placeId, pos);
        }
        function processPlaceCreation(placeId, pos){
            local placeDef = ::Places[placeId];

            local placeFileName = placeDef.getPlaceFileName();
            if(placeFileName == null) return;

            local dataPointPath = "res://build/assets/places/" + placeFileName + "/dataPoints.txt";
            if(!_system.exists(dataPointPath)){
                return;
            }

            local scriptPath = "res://build/assets/places/" + placeFileName + "/script.nut";
            if(!_system.exists(scriptPath)){
                return;
            }

            _doFile(scriptPath);
            if(!::PlaceScriptObject.rawin("processDataPointCreation")){
                return;
            }

            local dataPoints = _gameCore.DataPointFile();
            dataPoints.readFile(dataPointPath);

            local data = array(2);
            for(local i = 0; i < dataPoints.getNumDataPoints(); i++){
                dataPoints.getDataPointAt(i, data);
                local val = data[1];
                local major = (val >> 16) & 0xFFFF;
                local minor = val & 0xFFFF;
                //processDataPoint(data[0], major, minor);

                ::PlaceScriptObject.processDataPointCreation(mCreatorWorld_, pos + data[0] - placeDef.mCentre, major, minor, mDecoratioNode_);
            }

        }
        function destroy(){
            if(mLandItem_ != null){
                mLandNode_.getPosition();
                local name = mLandItem_.getName();
                mLandNode_.destroyNodeAndChildren();
                //Remove afterwards so there are no references to it.
                _graphics.removeManualMesh(name);
            }
        }
    }

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mTerrain_ = [];

        local requestedZoom = ::Base.mPlayerStats.getExplorationCurrentZoom();
        if(requestedZoom != null){
            mCurrentZoomLevel_ = requestedZoom;
        }

        mCurrentFoundRegions_ = {};
        mRegionEntries_ = {};

        _event.subscribe(Event.REQUEST_WORLD_VIEW_CHANGE, receiveWorldViewChangeRequest, this);

        //TODO consider moving this somewhere else.
        _event.transmit(Event.GAMEPLAY_SESSION_STARTED, null);
    }

    function getMapData(){
        return mMapData_;
    }

    #Override
    function getWorldType(){
        return WorldTypes.PROCEDURAL_EXPLORATION_WORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Procedural Exploration";
    }

    #Override
    function notifyPreparationComplete_(){
        mReady_ = true;
        base.setup();
        resetSession(mWorldPreparer_.getOutputData(), mWorldPreparer_.getOutputNativeData());
    }

    function resetSession(mapData, nativeMapData){
        //local nativeMapData = _gameCore.tableToExplorationMapData(mapData);
        //::currentNativeMapData <- nativeMapData;
        //_gameCore.setNewMapData(nativeMapData);
        ::currentNativeMapData = null;
        ::currentNativeMapData <- nativeMapData;
        _gameCore.setNewMapData(nativeMapData);
        //TODO would prefer to have the base call further up.
        createScene();

        ABOVE_GROUND = 0xFF - mapData.seaLevel;

        base.resetSession();

        mMapData_ = mapData;

        voxeliseMap();

        mCloudManager_ = CloudManager(mParentNode_, mMapData_.width * 3, mMapData_.height * 3, -mMapData_.width, -mMapData_.height);
        mWindStreakManager_ = WindStreakManager(mParentNode_, mMapData_.width, mMapData_.height);

        setupPlaces();
        createPlacedItems();

        if(mPlayerEntry_ != null){
            local startX = (mMapData_.playerStart >> 16) & 0xFFFF;
            local startY = mMapData_.playerStart & 0xFFFF;
            local pos = Vec3(startX, 0, -startY);
            pos.y = getZForPos(pos);
            mPlayerEntry_.setPosition(pos);
            notifyPlayerMoved();
        }

        if(false){
            local rel = mMapData_.width / 1024.0;
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION);
            for(local y = 0; y < 3; y++){
                for(local x = 0; x < 3; x++){
                    local terrain = _scene.createTerrain(camera);
                    terrain.load("height.png", Vec3(mMapData_.width/2 + mMapData_.width * x - (mMapData_.width), 0, -mMapData_.height/2 + mMapData_.height * y - (mMapData_.height)), Vec3(mMapData_.width + rel, 100, mMapData_.height + rel));
                    local node = _scene.getRootSceneNode().createChildSceneNode(_SCENE_STATIC);
                    node.attachObject(terrain);
                    terrain.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);

                    mTerrain_.append(terrain);
                }
            }
        }
    }

    function shutdown(){
        //Destroy the land nodes before anything else so their items can be queried.
        foreach(i in mRegionEntries_){
            i.destroy();
        }
        mRegionEntries_.clear();

        _gameCore.destroyMapData(::currentNativeMapData);
        ::currentNativeMapData = null;

        _event.unsubscribe(Event.REQUEST_WORLD_VIEW_CHANGE, receiveWorldViewChangeRequest, this);

        base.shutdown();
    }

    #Override
    function zoomChanged_(){
        if(!mWorldViewActive_) return;

        mCurrentZoomLevel_ = WORLD_VIEW_DISTANCE;
        setWorldZoomState(false);
    }

    function receiveWorldViewChangeRequest(id, data){
        toggleWorldZoomState();
    }

    function getPositionForAppearEnemy_(enemyType){
        //TODO in future have a more sophisticated method to solve this, for instance spawn locations stored in entity defs.
        if(enemyType == EnemyId.SQUID){
            return MapGenHelpers.findRandomPositionInWater(mMapData_, 0);
        }else{
            return MapGenHelpers.findRandomPointOnLand(mMapData_, mPlayerEntry_.getPosition(), 100);
        }
    }

    function getPositionForAppearDistraction_(){
        return MapGenHelpers.findRandomPointOnLand(mMapData_, mPlayerEntry_.getPosition(), 200, 100);
    }

    function updateWaterBlock(waterBlock){
        if(waterBlock != null){
            waterBlock.setDetailMapOffset(0, Vec2(sin(mAnimIncrement_ * 0.1), mAnimIncrement_ * 0.05));
        }
    }

    function update(){
        if(!isActive()) return;

        base.update();
        checkForEnemyAppear();
        checkForDistractionAppear();

        mAnimIncrement_ += 0.01;
        updateWaterBlock(mWaterDatablock_);
        updateWaterBlock(mOutsideWaterDatablock_);
        if(mAnimIncrement_ >= 1000.0){
            mAnimIncrement_ = 0.0;
        }

        mCloudManager_.update();
        mWindStreakManager_.update();

        foreach(c,i in mRegionEntries_){
            i.update();
        }

        checkWorldZoomState();

        if(mTerrain_ != null){
            foreach(i in mTerrain_){
                i.update();
            }
        }
    }

    function checkForEnemyAppear(){
        if(::Base.isProfileActive(GameProfile.DISABLE_ENEMY_SPAWN)) return;

        local foundSomething = _random.randInt(1000) == 0;
        if(!foundSomething) return;
        if(mActiveEnemies_.len() >= 20){
            print("can't add any more enemies");
            return;
        }
        //appearEnemy(_random.randInt(EnemyId.GOBLIN, EnemyId.MAX-1));
        local pos = MapGenHelpers.findRandomPointOnLand(mMapData_, mPlayerEntry_.getPosition(), 50);
        if(pos == null){
            return;
        }
        appearEnemy(pos);
    }

    function checkForDistractionAppear(){
        return;
        if(::Base.isProfileActive(GameProfile.DISABLE_DISTRACTION_SPAWN)) return;

        mAppearDistractionLogic_.update();

        local target = getPositionForAppearDistraction_();
        if(target == null) return;
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.PERCENTAGE_ENCOUNTER)){
            mEntityFactory_.constructPercentageEncounter(target, mGui_);
        }
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.HEALTH_ORB)){
            mEntityFactory_.constructHealthOrbEncounter(target);
        }
        if(mAppearDistractionLogic_.checkAppearForObject(WorldDistractionType.EXP_ORB)){
            mEntityFactory_.constructEXPTrailEncounter(target);
        }
    }

    #Override
    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();

    }

    function easeOutQuat(x) {
        return 1 - pow(1 - x, 4);
    }
    function updateCameraPosition(){
        local zPos = getZForPos(mPosition_);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local targetDistance = mWorldViewActive_ ? WORLD_VIEW_DISTANCE : mCurrentZoomLevel_
        if(mWorldViewAnim_ < 1.0){
            mWorldViewAnim_ += 0.04;
            if(mWorldViewActive_){
                targetDistance = mCurrentZoomLevel_ + (WORLD_VIEW_DISTANCE - mCurrentZoomLevel_) * easeOutQuat(mWorldViewAnim_);
            }else{
                targetDistance = WORLD_VIEW_DISTANCE - (WORLD_VIEW_DISTANCE - mCurrentZoomLevel_) * easeOutQuat(mWorldViewAnim_);
            }
        }
        local zoom = targetDistance;
        setShadowFarDistance(30 + zoom * 2);

        local xPos = cos(mRotation_.x)*zoom;
        local yPos = sin(mRotation_.x)*zoom;
        local rot = Vec3(xPos, 0, yPos);
        yPos = sin(mRotation_.y)*zoom;
        rot += Vec3(0, yPos, 0);

        parentNode.setPosition(Vec3(mPosition_.x, zPos, mPosition_.z) + rot );
        camera.lookAt(mPosition_.x, zPos, mPosition_.z);
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
        }

        if(_input.getButtonAction(::InputManager.zoomIn)){
            mCurrentZoomLevel_ -= 0.5;
        }
        if(_input.getButtonAction(::InputManager.zoomOut)){
            mCurrentZoomLevel_ += 0.5;
        }

        if(mCurrentZoomLevel_ < MIN_ZOOM) mCurrentZoomLevel_ = MIN_ZOOM;

        ::Base.mPlayerStats.setExplorationCurrentZoom(mCurrentZoomLevel_);

        setShadowFarDistance(30 + mCurrentZoomLevel_ * 2);

        updateCameraPosition();
    }

    function checkWorldZoomState(){
        if(_input.getButtonAction(mInputs_.toggleWorldView, _INPUT_PRESSED)){
            _event.transmit(Event.REQUEST_WORLD_VIEW_CHANGE, null);
            //setWorldZoomState(!mWorldViewActive_);
        }
    }

    function toggleWorldZoomState(){
        setWorldZoomState(!mWorldViewActive_);
    }

    function setWorldZoomState(worldZoom){
        mWorldViewActive_ = worldZoom;
        mWorldViewAnim_ = 0.0;
    }

    #Override
    function updateMapViewerPlayerPosition_(playerPos){
        local p = playerPos.copy();
        p.z = -p.z;
        base.updateMapViewerPlayerPosition_(p);
    }

    #Override
    function getZForPos(pos){
        //Move somewhere else.

        /*
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local width = mMapData_.width;
        local height = mMapData_.height;
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;

        local buf = mMapData_.voxelBuffer;
        buf.seek((x + y * width) * 4);
        local voxFloat = (buf.readn('i') & 0xFF).tofloat();
        local altitude = (((voxFloat - mMapData_.seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
        local clampedAltitude = altitude < 0 ? 0 : altitude;

        return 0.5 + clampedAltitude * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
        */

        local voxFloat = ::currentNativeMapData.getAltitudeForPos(pos).tofloat();

        local altitude = (((voxFloat - mMapData_.seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
        local clampedAltitude = altitude < 0 ? 0 : altitude;

        return 0.5 + clampedAltitude * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
    }

    function getWaterDatablock_(name, outside=false){
        local waterBlock = _hlms.getDatablock(name);
        if(waterBlock == null){
            local blend = _hlms.getBlendblock({
                "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA
            });

            waterBlock = _hlms.pbs.createDatablock(name, blend);
            //waterBlock.setMacroblock(_hlms.getMacroblock( { "polygonMode": _PM_WIREFRAME } ));
            waterBlock.setMacroblock(_hlms.getMacroblock( { "polygonMode": _PM_SOLID } ));
        }
        local sampler = _hlms.getSamplerblock({
            "mag": "point"
        });
        local wrapSampler = _hlms.getSamplerblock({
            "u": "wrap",
            "v": "wrap",
            "w": "wrap",
            "mag": "point"
        });
        waterBlock.setWorkflow(_PBS_WORKFLOW_METALLIC);
        if(!outside){
        //waterBlock.setTexture(_PBSM_DIFFUSE, "checkerPattern.png");
        waterBlock.setTexture(_PBSM_DIFFUSE, "testTexture");
        //waterBlock.setTexture(_PBSM_DIFFUSE, "testTexture");
        //waterBlock.setTexture(_PBSM_DIFFUSE, "red.png");
        //waterBlock.setDiffuse(1, 1, 1);
        //waterBlock.setTexture(_PBSM_DETAIL0, "testTexture");
        waterBlock.setTexture(_PBSM_DETAIL_WEIGHT, "testTextureMask");
        }else{
            waterBlock.setTexture(_PBSM_DIFFUSE, "blueTexture");
        }
        waterBlock.setSamplerblock(_PBSM_DIFFUSE, sampler);
        waterBlock.setTexture(_PBSM_DETAIL0, "waterWaves.png");

        waterBlock.setDetailMapOffset(0, Vec2(0.5, 0.5));
        //waterBlock.setDetailMapWeight(0, 0.1);
        //waterBlock.setDetailMapWeight(0, 0.5);
        //waterBlock.setDetailMapOffset(0, Vec2());
        //waterBlock.setDetailMapScale(0, Vec2(1, 1));
        //waterBlock.setDetailMapBlendMode(0, 9);
        waterBlock.setSamplerblock(_PBSM_DETAIL0, wrapSampler);

        //print(waterBlock.getMetalness());
        //assert(false);
        waterBlock.setRoughness(1.0);
        waterBlock.setMetalness(0.0);

        //waterBlock.setTexture(_PBSM_DETAIL1, "waterWaves.png");

        //waterBlock.setSamplerblock(_PBSM_DETAIL1, wrapSampler);

        //waterBlock.setDetailMapOffset(1, Vec2(0.5, 0));
        waterBlock.setDetailMapScale(0, Vec2(20, 20));
        //waterBlock.setDetailMapWeight(0, 1);
        //waterBlock.setUserValue(0, 1.0, 0.0, 0.0, 0.0);

        _gameCore.setHlmsFlagForDatablock(waterBlock, 1 << 3);

        return waterBlock
    }

    function createScene(){
        //mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        if(mMapData_){
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            assert(camera != null);
            local parentNode = camera.getParentNode();
            parentNode.setPosition(0, 40, 60);
            camera.lookAt(0, 0, 0);
            //TODO This negative coordinate is incorrect.
            //parentNode.setPosition(mMapData_.width / 2, 40, -mMapData_.height / 2);
        }

        local planes = [];
        local waterBlock = getWaterDatablock_("waterBlock");
        local surroundBlock = getWaterDatablock_("outsideWaterBlock", true);
        for(local y = 0; y < 3; y++)
        for(local x = 0; x < 3; x++){
            //Create the ocean plane
            local oceanNode = mParentNode_.createChildSceneNode(_SCENE_STATIC);
            local oceanItem = _scene.createItem("waterPlaneMesh", _SCENE_STATIC);
            oceanItem.setCastsShadows(false);
            _gameCore.writeFlagsToItem(oceanItem, HLMS_OCEAN_VERTICES | HLMS_FLOOR_DECALS);
            oceanItem.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_WATER);
            oceanItem.setDatablock(surroundBlock);
            oceanNode.attachObject(oceanItem);
            //NOTE: As we're re-orientating later 1 must be the scale for z
            oceanNode.setScale(300 + (1.0/100.0) * 300, 1, 300 + (1.0/100.0) * 300);
            oceanNode.setPosition((x * 600) - 300 + ((1.0/100.0) * 300), 0, (y * 600) + -300 + ((1.0/100.0) * 300) - 600);
            //oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
            planes.append(oceanItem);
            //oceanNode.setVisible(false);
        }

        planes[4].setDatablock(waterBlock);

        mWaterDatablock_ = waterBlock;
        mOutsideWaterDatablock_ = surroundBlock;

    }

    function voxeliseMap(){
        assert(mMapData_ != null);

        local parentVoxNode = mParentNode_.createChildSceneNode();
        local regionNode = parentVoxNode.createChildSceneNode();
        //local vox = VoxToMesh(Timer());

        local t = Timer();
        t.start();
        local meshes = _gameCore.createTerrainFromMapData("test", currentNativeMapData);
        //local meshes = vox.createTerrainFromVoxelBlob("test", mMapData_);
        t.stop();
        print("Time taken to generate voxel map " + t.getSeconds());

        //print("Time taken to generate voxel map " + vox.getStats().totalSeconds);
        foreach(c,i in meshes){
            if(i == null) continue;
            local decorationNode = regionNode.createChildSceneNode(_SCENE_STATIC);

            local item = _scene.createItem(i, _SCENE_STATIC);
            _gameCore.writeFlagsToItem(item, HLMS_PACKED_VOXELS | HLMS_TERRAIN | HLMS_FLOOR_DECALS);
            item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION_TERRRAIN_UNDISCOVERED);
            item.setCastsShadows(false);
            local landNode = regionNode.createChildSceneNode(_SCENE_STATIC);
            landNode.attachObject(item);
            landNode.setScale(1, 1, PROCEDURAL_WORLD_UNIT_MULTIPLIER);
            landNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
            landNode.setVisible(true);
            item.setDatablock("baseVoxelMaterial");

            mRegionEntries_.rawset(c, ProceduralRegionEntry(this, mEntityManager_, landNode, decorationNode));
        }
    }

    function setupPlaces(){
        //TODO see about getting rid of this.
        mActivePlaces_ = [];
        local placer = ::PlacePlacer();
        foreach(c,i in mMapData_.placeData){
            local regionEntry = mRegionEntries_[i.region];

            local node = regionEntry.mDecoratioNode_;
            local placeDefine = ::Places[i.placeId];

            placer.placeIntoWorld(i, placeDefine, node, this, regionEntry, c);

            //local beaconEntity = mEntityFactory_.constructPlaceIndicatorBeacon(placeEntry.getPosition());
            //mActivePlaces_.append(placeEntry);
            //regionEntry.pushPlace(placeEntry, null);
        }
    }

    function createPlacedItems(){
        local list = mMapData_.placedItems;
        //Check for nulls in the list.
        local i = 0;
        while(i < list.len()){
            if(list[i] == null){
                list.remove(i);
            }else{
                i++;
            }
        }

        foreach(c,i in list){
            //When generating places check if one of them has a point in the blob and if so set that placed item to null, then later remove.
            local node = mRegionEntries_[i.region].mDecoratioNode_;
            mEntityFactory_.constructPlacedItem(node, i, c);
            //mActivePlaces_.append(itemEntry);
        }
    }

    function getTraverseTerrainForPosition(pos){
        return ::MapGenHelpers.getTraverseTerrainForPosition(mMapData_, pos);
    }
    function getIsWaterForPosition(pos){
        local x = pos.x;
        local y = -pos.z;
        //The endless ocean...
        if(x < 0 || y < 0 || x >= mMapData_.width || y >= mMapData_.height) return true;
        return ::MapGenHelpers.getIsWaterForPosition(mMapData_, pos);
    }

    #Override
    function processWorldActiveChange_(active){
        //Re-check the visibility of the nodes.
        foreach(i in mRegionEntries_){
            i.setWorldActive(active);
        }
    }
    #Override
    function processWorldCurrentChange_(current){
        if(mParentNode_ != null) mParentNode_.setVisible(current);
    }

    function notifyPlayerVoxelChange(){
        local playerPos = mPlayerEntry_.getPosition();
        local radius = 4;

        local circleX = playerPos.x;
        local circleY = -playerPos.z;

        //The coordinates of the circle's rectangle
        local startX = circleX - radius;
        local startY = circleY - radius;
        local endX = circleX + radius;
        local endY = circleY + radius;

        //Find the actual chunk coordinates that lie within the circle's rectangle
        local startXTile = floor(startX);
        local startYTile = floor(startY);
        local endXTile = ceil(endX);
        local endYTile = ceil(endY);

        //Hold a reference to the function to avoid the mapGenHelpers lookup each time.
        local targetFunc = ::MapGenHelpers.getRegionForData;

        //local mapWidth = mMapData_.width;
        //local mapHeight = mMapData_.height;

        local foundRegions = {};
        for (local y = startYTile; y < endYTile; y++){
            for (local x = startXTile; x < endXTile; x++){
                //Go through these chunks to determine what to load.
                if(_checkRectCircleCollision(x, y, radius, circleX, circleY)){
                    //if(x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) continue;
                    //Query the voxel data and determine what the region is.
                    local targetRegion = targetFunc(mMapData_, playerPos);
                    if(targetRegion < 0) continue;
                    //print("Found target region " + targetRegion);
                    foundRegions.rawset(targetRegion, true);
                }
            }
        }

        foreach(c,i in foundRegions){
            if(!mCurrentFoundRegions_.rawin(c)){
                print("Found new region " + c);
                processFoundNewRegion(c);
            }
        }
    }
    function _checkRectCircleCollision(tileX, tileY, radius, circleX, circleY){
        local distX = abs(circleX - (tileX)-0.5);
        local distY = abs(circleY - (tileY)-0.5);

        if(distX > (0.5 + radius)) return false;
        if(distY > (0.5 + radius)) return false;

        if(distX <= (0.5)) return true;
        if(distY <= (0.5)) return true;

        local dx = distX - 0.5;
        local dy = distY - 0.5;

        return (dx*dx+dy*dy<=(radius*radius));
    }

    function processRegionCollectables_(regionEntry){
        if(regionEntry.rawin("collectables")){
            foreach(i in regionEntry.collectables){
                mEntityFactory_.constructEXPTrailEncounter(Vec3(i.x, 0, -i.y));
            }
        }
    }
    function regionDiscoveredSpawnEnemy(regionEntry, pos){
        print(regionEntry.type);
        if(regionEntry.type == RegionType.NONE){
            if(_random.randInt(6) == 0){
                createEnemy(EnemyId.BEE_HIVE, pos);
                return;
            }
        }
        appearEnemy(pos);
    }
    function processRegionDiscovered_(regionEntry){
        local e = regionEntry.coords[_random.randIndex(regionEntry.coords)];

        local startX = (e >> 16) & 0xFFFF;
        local startY = e & 0xFFFF;
        local pos = Vec3(startX, 0, -startY);

        regionDiscoveredSpawnEnemy(regionEntry, pos);
        //createEnemy(EnemyId.GOBLIN, pos);
        //print(regionEntry.coords);

        local targetBiome = ::MapGenHelpers.getBiomeForRegionType(regionEntry.type);
        local discoveredData = ::Base.mPlayerStats.processBiomeDiscovered(targetBiome);
        if(discoveredData != null){
            local biomeData = ::Biomes[targetBiome];
            if(mGui_){
                local popupData = ::PopupManager.PopupData(Popup.REGION_DISCOVERED, { "biome": biomeData });
                mGui_.showPopup(popupData);
            }

            discoveredData.biome <- biomeData;
            _event.transmit(Event.BIOME_DISCOVER_STATS_CHANGED, discoveredData);
        }
    }
    function discoverRegion(regionId){
        if(regionId > 0 && regionId < mMapData_.regionData.len()){
            processFoundNewRegion(regionId);
            return true;
        }
        return false;
    }
    function processFoundNewRegion(regionId){
        if(regionId == INVALID_REGION_ID) return;
        if(regionId >= mMapData_.regionData.len()) return;
        if(_gameCore.getRegionFound(regionId)) return;

        _gameCore.setRegionFound(regionId, true);
        local regionData = mMapData_.regionData[regionId];
        if(mRegionEntries_.rawin(regionId)){
            mCurrentFoundRegions_.rawset(regionId, true);
            //A mesh for this region is present so perform the animation.
            local regionEntry = mRegionEntries_[regionId];
            if(regionEntry != null){
                regionEntry.performArrival();
                //::PopupManager.displayPopup(::PopupManager.PopupData(Popup.REGION_DISCOVERED, regionData.type));
            }
        }

        processRegionCollectables_(regionData);
        processRegionDiscovered_(regionData);
        if(mGui_.mWorldMapDisplay_.mMapViewer_ != null){
            local viewer = mGui_.mWorldMapDisplay_.mMapViewer_;
            //TODO hack when moving around worlds, really this check should never be needed.
            if(viewer.rawin("notifyRegionFound")){
                viewer.notifyRegionFound(regionId);
            }
        }
    }

    function visitPlace(mapName){
        local data = {
            "mapName": mapName
        };
        local worldInstance = ::Base.mExplorationLogic.createWorldInstance(WorldTypes.VISITED_LOCATION_WORLD, data);
        ::Base.mExplorationLogic.pushWorld(worldInstance);
    }

    function findAllRegions(){
        foreach(c,i in mRegionEntries_){
            processFoundNewRegion(c);
        }
    }

    function getCurrentFoundRegions(){
        return mCurrentFoundRegions_;
    }

    function getStatsString(){
        local outString = "";
        outString += format("World Seed: %i\n", mMapData_.seed);
        outString += format("Moisture Seed: %i\n", mMapData_.moistureSeed);
        outString += format("Variation Seed: %i\n", mMapData_.variationSeed);

        return outString;
    }
};