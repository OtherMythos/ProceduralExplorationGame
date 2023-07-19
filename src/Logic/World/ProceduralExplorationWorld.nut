//TODO get rid of this.
::ExplorationCount <- 0;

::ProceduralExplorationWorld <- class extends ::World{
    mMapData_ = null;

    static WORLD_DEPTH = 20;
    ABOVE_GROUND = null;
    mVoxMesh_ = null;

    mActivePlaces_ = null;

    constructor(){
        base.constructor();
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
            "seed": _random.randInt(0, 1000),
            "moistureSeed": _random.randInt(0, 1000),
            "variation": _random.randInt(0, 1000),
            "width": 200,
            "height": 200,
            "numRivers": 24,
            "seaLevel": 100,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);

        resetSession(outData);
    }

    function resetSession(mapData){
        //TODO would prefer to have the base call further up.
        createScene();

        ABOVE_GROUND = 0xFF - mapData.seaLevel;

        base.resetSession();

        mMapData_ = mapData;

        voxeliseMap();

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

    function updatePlayerPos(playerPos){
        base.updatePlayerPos(playerPos);

        updateCameraPosition();
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

    function getZForPos(pos){
        //Move somewhere else.

        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local buf = mMapData_.voxelBuffer;
        buf.seek((x + y * mMapData_.width) * 4);
        local voxFloat = (buf.readn('i') & 0xFF).tofloat();
        local altitude = (((voxFloat - mMapData_.seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
        local clampedAltitude = altitude < 0 ? 0 : altitude;

        return clampedAltitude * 0.4;
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();
        //::ExplorationEntityFactory.mBaseSceneNode_ = mParentNode_;
        //::ExplorationEntityFactory.mCharacterGenerator_ = ::CharacterGenerator();

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
        oceanItem.setRenderQueueGroup(30);
        oceanItem.setDatablock("oceanUnlit");
        oceanNode.attachObject(oceanItem);
        oceanNode.setScale(500, 500, 500)
        oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

    }

    function voxeliseMap(){
        assert(mMapData_ != null);
        local width = mMapData_.width;
        local height = mMapData_.height;
        local voxData = array(width * height * WORLD_DEPTH, null);
        local buf = mMapData_.voxelBuffer;
        buf.seek(0);
        local voxVals = [
            2, 112, 0, 147, 6
        ];
        local waterVal = 192;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local vox = buf.readn('i')
                local voxFloat = (vox & 0xFF).tofloat();
                if(voxFloat <= mMapData_.seaLevel) continue;
                //+1 because vox values at 0 still need to be drawn.
                local altitude = (((voxFloat - mMapData_.seaLevel) / ABOVE_GROUND) * WORLD_DEPTH).tointeger() + 1;
                local voxelMeta = (vox >> 8) & MAP_VOXEL_MASK;
                local isRiver = (vox >> 8) & MapVoxelTypes.RIVER;
                if(isRiver){
                    altitude-=2;
                    if(altitude < 1) altitude = 1;
                }
                //if(voxFloat <= mMapData_.seaLevel) voxelMeta = 3;
                for(local i = 0; i < altitude; i++){
                    voxData[x + (y * width) + (i*width*height)] = isRiver ? waterVal : voxVals[voxelMeta];
                }
            }
        }
        local vox = VoxToMesh(Timer(), 1 << 2, 0.4);
        //TODO get rid of this with the proper function to destory meshes.
        ::ExplorationCount++;
        local meshObj = vox.createMeshForVoxelData("worldVox" + ::ExplorationCount, voxData, width, height, WORLD_DEPTH);
        mVoxMesh_ = meshObj;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(30);
        local landNode = mParentNode_.createChildSceneNode();
        landNode.attachObject(item);
        landNode.setScale(1, 1, 0.4);
        landNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        vox.printStats();
    }

    function setupPlaces(){
        mActivePlaces_ = [];
        foreach(c,i in mMapData_.placeData){
            local placeEntry = mEntityFactory_.constructPlace(i, c, ::Base.mExplorationLogic.mGui_);
            mActivePlaces_.append(placeEntry);
        }
    }

    function createPlacedItems(){
        foreach(c,i in mMapData_.placedItems){
            local itemEntry = mEntityFactory_.constructPlacedItem(i, c);
            mActivePlaces_.append(itemEntry);
        }
    }

    function getTraverseTerrainForPosition(pos){
        return ::MapGenHelpers.getTraverseTerrainForPosition(mMapData_, pos);
    }
    function getIsWaterForPosition(pos){
        return ::MapGenHelpers.getIsWaterForPosition(mMapData_, pos);
    }

    function processActiveChange_(active){
        if(!active){
            destroyEnemyMap_(mActivePlaces_);
        }
    }
};