::ProceduralExplorationWorld <- class extends ::World{
    mMapData_ = null;

    static WORLD_DEPTH = 20;
    ABOVE_GROUND = null;
    mVoxMesh_ = null;
    mWorldViewActive_ = false;

    mActivePlaces_ = null;
    mCurrentFoundRegions_ = null;
    mRegionEntries_ = null;

    mCloudManager_ = null;

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
            if(mAnimCount_ < 0) return;
            local animIdx = mAnimCount_.tofloat() / mMaxAnim_.tofloat();
            mAnimCount_--;
            local animPos = mAnimCount_ * -0.10;
            mLandNode_.setPosition(0, animPos, 0);
            mDecoratioNode_.setPosition(0, animPos, 0);
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
            }

            if(vis){
                for(local i = 0; i < mPlaceIds_.len(); i++){
                    //Perform the spawn functions for the specific place
                    local placeData = mPlaceIds_[i];
                    local placeDef = ::Places[placeData[0]];
                    local appearFunction = placeDef.getRegionAppearFunction();
                    if(appearFunction != null){
                        appearFunction(mCreatorWorld_, placeData[0], placeData[1]);
                    }
                }
            }

            foreach(i in mPlaces_){
                //TODO this will be massively inefficient so improve that
                i.getSceneNode().setVisible(vis);
            }
            foreach(i in mBeacons_){
                local node = mEntityManager_.getComponent(i, EntityComponents.SCENE_NODE).mNode;
                node.setVisible(mWorldActive_ && !mVisible_);
            }
            mDecoratioNode_.setVisible(vis);
        }
        function pushPlace(place, beacon){
            mPlaces_.append(place);
            mBeacons_.append(beacon);
        }
        function pushFuncPlace(placeId, pos){
            mPlaceIds_.append([placeId, pos]);
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

        local requestedZoom = ::Base.mPlayerStats.getExplorationCurrentZoom();
        if(requestedZoom != null){
            mCurrentZoomLevel_ = requestedZoom;
        }

        mCurrentFoundRegions_ = {};
        mRegionEntries_ = {};

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
        ::currentNativeMapData <- nativeMapData;
        _gameCore.setNewMapData(nativeMapData);
        //TODO would prefer to have the base call further up.
        createScene();

        ABOVE_GROUND = 0xFF - mapData.seaLevel;

        base.resetSession();

        mMapData_ = mapData;

        voxeliseMap();

        mCloudManager_ = CloudManager(mParentNode_, mMapData_.width, mMapData_.height);

        setupPlaces();
        createPlacedItems();

        local startX = (mMapData_.playerStart >> 16) & 0xFFFF;
        local startY = mMapData_.playerStart & 0xFFFF;
        local pos = Vec3(startX, 0, -startY);
        pos.y = getZForPos(pos);
        mPlayerEntry_.setPosition(pos);
        notifyPlayerMoved();
    }

    function shutdown(){
        //Destroy the land nodes before anything else so their items can be queried.
        foreach(i in mRegionEntries_){
            i.destroy();
        }
        mRegionEntries_.clear();

        base.shutdown();
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

    function update(){
        if(!isActive()) return;

        base.update();

        mCloudManager_.update();

        foreach(c,i in mRegionEntries_){
            i.update();
        }

        checkWorldZoomState();
    }

    #Override
    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();

    }

    function updateCameraPosition(){
        local zPos = getZForPos(mPosition_);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        assert(camera != null);
        local parentNode = camera.getParentNode();

        local zoom = mWorldViewActive_ ? 300 : mCurrentZoomLevel_

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
        ::Base.mPlayerStats.setExplorationCurrentZoom(mCurrentZoomLevel_);

        if(mCurrentZoomLevel_ < MIN_ZOOM) mCurrentZoomLevel_ = MIN_ZOOM;

        updateCameraPosition();
    }

    function checkWorldZoomState(){
        if(_input.getButtonAction(mInputs_.toggleWorldView, _INPUT_PRESSED)){
            setWorldZoomState(!mWorldViewActive_);
        }
    }

    function setWorldZoomState(worldZoom){
        mWorldViewActive_ = worldZoom;
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

        //Create the ocean plane
        local oceanNode = mParentNode_.createChildSceneNode();
        local oceanItem = _scene.createItem("plane");
        oceanItem.setCastsShadows(false);
        oceanItem.setRenderQueueGroup(30);
        oceanItem.setDatablock("oceanUnlit");
        oceanNode.attachObject(oceanItem);
        //NOTE: As we're re-orientating later 1 must be the scale for z
        oceanNode.setScale(2000, 2000, 1);
        oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

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
            local decorationNode = regionNode.createChildSceneNode();

            local item = _scene.createItem(i);
            item.setRenderQueueGroup(30);
            item.setCastsShadows(false);
            local landNode = regionNode.createChildSceneNode();
            landNode.attachObject(item);
            landNode.setScale(1, 1, PROCEDURAL_WORLD_UNIT_MULTIPLIER);
            landNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
            landNode.setVisible(true);

            mRegionEntries_.rawset(c, ProceduralRegionEntry(this, mEntityManager_, landNode, decorationNode));
        }
    }

    function setupPlaces(){
        //TODO see about getting rid of this.
        mActivePlaces_ = [];
        foreach(c,i in mMapData_.placeData){
            local regionEntry = mRegionEntries_[i.region];

            local node = regionEntry.mDecoratioNode_;
            local placeData = ::Places[i.placeId];
            local placementFunction = placeData.getPlacementFunction();
            local placeEntry = (placeData.getPlacementFunction())(this, mEntityFactory_, node, i, c);
            local pos = Vec3(i.originX, 0, -i.originY);
            if(placeData.getRegionAppearFunction() != null){
                regionEntry.pushFuncPlace(i.placeId, pos);
            }
            if(placeEntry == null) continue;

            //local placeEntry = mEntityFactory_.constructPlace(i, c, ::Base.mExplorationLogic.mGui_);
            local beaconEntity = mEntityFactory_.constructPlaceIndicatorBeacon(pos);
            mActivePlaces_.append(placeEntry);
            regionEntry.pushPlace(placeEntry, beaconEntity);
        }
    }

    function createPlacedItems(){
        foreach(c,i in mMapData_.placedItems){
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
            //print("Discovered " + biomeData.getName());
            ::PopupManager.displayPopup(::PopupManager.PopupData(Popup.REGION_DISCOVERED, biomeData));
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