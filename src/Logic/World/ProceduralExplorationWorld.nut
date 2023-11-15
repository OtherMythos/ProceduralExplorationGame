//TODO get rid of this.
::ExplorationCount <- 0;

::ProceduralExplorationWorld <- class extends ::World{
    mMapData_ = null;

    static WORLD_DEPTH = 20;
    ABOVE_GROUND = null;
    mVoxMesh_ = null;

    mActivePlaces_ = null;
    mCurrentFoundRegions_ = null;
    mRegionEntries_ = null;

    mCloudManager_ = null;

    ProceduralRegionEntry = class{
        mEntityManager_ = null;
        mLandNode_ = null;
        mLandItem_ = null;
        mDecoratioNode_ = null;
        mVisible_ = false;
        mWorldActive_ = false;

        mPlaces_ = null;
        mBeacons_ = null;

        mAnimCount_ = -1;
        mMaxAnim_ = 30;

        constructor(entityManager, node, decorationNode){
            mEntityManager_ = entityManager;
            mLandNode_ = node;
            mDecoratioNode_ = decorationNode;
            if(mLandNode_){
                mLandItem_ = mLandNode_.getAttachedObject(0);
            }
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
    }

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);

        mCurrentFoundRegions_ = {};
        mRegionEntries_ = {};
    }

    function setup(){
        base.setup();

        resetSessionGenMap();
    }

    function getMapData(){
        return mMapData_;
    }

    function getWorldType(){
        return WorldTypes.PROCEDURAL_EXPLORATION_WORLD;
    }

    //TODO long term remove this and generate the map data somewhere else so it can be threaded easier.
    function resetSessionGenMap(){
        local gen = ::MapGen();
        local data = {
            "seed": 77749,
            "moistureSeed": 84715,
            "variation": 0,
            "width": 400,
            "height": 400,
            "numRivers": 24,
            "seaLevel": 100,
            "numRegions": 16,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);
        print("World generation completed in " + outData.stats.totalSeconds);

        resetSession(outData);
    }

    #Override
    function notifyPreparationComplete_(){
        mReady_ = true;
        base.setup();
        resetSession(mWorldPreparer_.getOutputData());
    }

    function resetSession(mapData){
        //TODO would prefer to have the base call further up.
        createScene();

        ABOVE_GROUND = 0xFF - mapData.seaLevel;

        base.resetSession();

        mMapData_ = mapData;

        voxeliseMap();

        mCloudManager_ = CloudManager(mParentNode_, mMapData_.width, mMapData_.height);

        setupPlaces();
        createPlacedItems();

        mPlayerEntry_.setPosition(Vec3(mMapData_.width / 2, 0, -mMapData_.height / 2));
    }

    function getPositionForAppearEnemy_(enemyType){
        //TODO in future have a more sophisticated method to solve this, for instance spawn locations stored in entity defs.
        if(enemyType == EnemyId.SQUID){
            return MapGenHelpers.findRandomPositionInWater(mMapData_, 0);
        }else{
            return MapGenHelpers.findRandomPointOnLand(mMapData_, mPlayerEntry_.getPosition(), 50);
        }
    }

    function update(){
        if(!isActive()) return;

        base.update();

        mCloudManager_.update();

        foreach(c,i in mRegionEntries_){
            i.update();
        }
    }

    #Override
    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();

        //Bodge some checks in.
        if(_input.getMouseButton(1)){
            //::Base.mExplorationLogic.spawnEXPOrbs(mPlayerEntry_.getPosition(), 4);
            //mCurrentWorld_.spawnEXPOrbs(mCurrentWorld_.mPlayerEntry_.getPosition(), 1);

            //gatewayEndExploration();
            //::Base.mExplorationLogic.pushWorld(::Base.mExplorationLogic.createWorldInstance(WorldTypes.PROCEDURAL_EXPLORATION_WORLD));

            ::_applyDamageOther(mEntityManager_, mPlayerEntry_.getEID(), 10000);
        }
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
        //Move somewhere else.

        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local buf = mMapData_.voxelBuffer;
        buf.seek((x + y * mMapData_.width) * 4);
        local voxFloat = (buf.readn('i') & 0xFF).tofloat();
        local altitude = (((voxFloat - mMapData_.seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
        local clampedAltitude = altitude < 0 ? 0 : altitude;

        return clampedAltitude * PROCEDURAL_WORLD_UNIT_MULTIPLIER;
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
        oceanNode.setScale(500, 500, 500)
        oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

    }

    function voxeliseMap(){
        assert(mMapData_ != null);

        local parentVoxNode = mParentNode_.createChildSceneNode();
        local regionNode = parentVoxNode.createChildSceneNode();
        local vox = VoxToMesh(Timer());
        local meshes = vox.createTerrainFromVoxelBlob("test", mMapData_);
        print("Time taken to generate voxel map " + vox.getStats().totalSeconds);
        assert(meshes.len() == mMapData_.regionData.len());
        foreach(c,i in meshes){
            local decorationNode = regionNode.createChildSceneNode();

            local item = _scene.createItem(i);
            item.setRenderQueueGroup(30);
            local landNode = regionNode.createChildSceneNode();
            landNode.attachObject(item);
            landNode.setScale(1, 1, PROCEDURAL_WORLD_UNIT_MULTIPLIER);
            landNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));
            landNode.setVisible(true);

            mRegionEntries_.rawset(c, ProceduralRegionEntry(mEntityManager_, landNode, decorationNode));
        }
    }

    function setupPlaces(){
        //TODO see about getting rid of this.
        mActivePlaces_ = [];
        foreach(c,i in mMapData_.placeData){
            local placeEntry = mEntityFactory_.constructPlace(i, c, ::Base.mExplorationLogic.mGui_);
            local beaconEntity = mEntityFactory_.constructPlaceIndicatorBeacon(Vec3(i.originX, 0, -i.originY));
            mActivePlaces_.append(placeEntry);
            mRegionEntries_[i.region].pushPlace(placeEntry, beaconEntity);
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
        return ::MapGenHelpers.getIsWaterForPosition(mMapData_, pos);
    }

    function processWorldActiveChange_(active){
        //Re-check the visibility of the nodes.
        foreach(i in mRegionEntries_){
            i.setWorldActive(active);
        }
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

        local foundRegions = {};
        for (local y = startYTile; y < endYTile; y++){
            for (local x = startXTile; x < endXTile; x++){
                //Go through these chunks to determine what to load.
                if(_checkRectCircleCollision(x, y, radius, circleX, circleY)){
                    //printf("Collided with %i %i", x, y);
                    //Query the voxel data and determine what the region is.
                    local targetRegion = targetFunc(mMapData_, playerPos);
                    //print("Found target region " + targetRegion);
                    foundRegions.rawset(targetRegion, true);
                }
            }
        }

        foreach(c,i in foundRegions){
            if(!mCurrentFoundRegions_.rawin(c)){
                mCurrentFoundRegions_.rawset(c, true);
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

    function processFoundNewRegion(regionId){
        assert(mRegionEntries_.rawin(regionId));
        local regionEntry = mRegionEntries_[regionId];
        if(regionEntry != null){
            regionEntry.performArrival();
            ::PopupManager.displayPopup(Popup.REGION_DISCOVERED);
        }
    }
};