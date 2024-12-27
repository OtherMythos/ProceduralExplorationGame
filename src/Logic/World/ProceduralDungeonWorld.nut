::ProceduralDungeonWorld <- class extends ::World{

    mMapData_ = null;
    mVoxMesh_ = null;

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);
    }

    #Override
    function getWorldType(){
        return WorldTypes.PROCEDURAL_DUNGEON_WORLD;
    }
    #Override
    function getWorldTypeString(){
        return "Dungeon";
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

        _gameCore.setupCollisionDataForWorld(mCollisionDetectionWorld_, mMapData_.vals);

        createScene();
        spawnEnemies();

        local targetPos = mMapData_.playerStart;
        local pos = Vec3(targetPos & 0xFFFF, 0, (targetPos >> 16) & 0xFFFF);
        pos *= 5;
        pos.y = getZForPos(pos);
        mPlayerEntry_.setPosition(pos);
        notifyPlayerMoved();
    }

    function getPositionForAppearEnemy_(enemyType){
        return Vec3();
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

    #Override
    function processWorldCurrentChange_(current){
        if(mParentNode_ != null) mParentNode_.setVisible(current);
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
        return 1;
    }

    function getWallMeshes(){
        switch(mMapData_.dungeonType){
            case ProceduralDungeonTypes.DUST_MITE_NEST:
                return [
                    "dustMiteNestDungeonFloor.voxMesh",
                    "dustMiteNestDungeonWall.voxMesh",
                    "dustMiteNestDungeonWallCorner.voxMesh"
                ];
            case ProceduralDungeonTypes.CATACOMB:
            default:
                return ["DungeonFloor.voxMesh", "DungeonWall.voxMesh", "DungeonWallCorner.voxMesh"];
        }
    }

    function spawnEnemies(){
        for(local i = 0; i < 3 + _random.randInt(3); i++){
            createEnemy(EnemyId.DUST_MITE_WORKER, findPosInDungeon_());
        }
    }

    function createScene(){
        local wallMeshes = getWallMeshes();

        local width = mMapData_.width;
        local height = mMapData_.height;
        local voxData = array(width * height, null);
        local v = mMapData_.vals;
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local val = v[x + y * width];
                if(val == false) continue;

                local mask = (val >> 24) & 0xF;

                local newNode = mParentNode_.createChildSceneNode();
                newNode.setPosition(x * 5, 0, y * 5);

                local itemName = wallMeshes[0];
                local orientation = Quat();
                if(mask == 0){
                }else{
                    if(mask == 0x2) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x4) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x8) orientation = Quat(0, 1, 0, 0);
                    itemName = wallMeshes[1];

                    if((mask & (mask - 1)) != 0){
                        //Two bits are true meaning this is a corner.
                        itemName = wallMeshes[2];
                        if(mask == 0x3) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                        if(mask == 0xA) orientation = Quat(0, 1, 0, 0);
                        if(mask == 0xC) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    }
                }

                local item = _gameCore.createVoxMeshItem(itemName);
                item.setRenderQueueGroup(30);
                newNode.attachObject(item);
                newNode.setOrientation(orientation);
            }
        }

        //Place some decorations around the dungeon
        for(local i = 0; i < 10 + _random.randInt(10); i++){
            local targetPos = findPosInDungeon_();

            local orientation = Quat(-PI/(_random.rand()*1.5+1), ::Vec3_UNIT_X);
            orientation *= Quat(_random.rand()*PI - PI/2, ::Vec3_UNIT_Y);
            local model = _random.randInt(3) == 0 ? "skeletonBody.voxMesh" : "skeletonHead.voxMesh";
            mEntityFactory_.constructSimpleItem(mParentNode_, model, targetPos, 0.25, null, null, 10, orientation);
        }

        mEntityFactory_.constructChestObject(findPosInDungeon_());

        mEntityFactory_.constructSimpleTeleportItem(mParentNode_, "ladderUp.voxMesh", findPosInDungeon_(), 0.5, {
            "actionType": ActionSlotType.ASCEND,
            "popWorld": true
        });
        local en = mEntityFactory_.constructSimpleTeleportItem(mParentNode_, "ladderDown.voxMesh", findPosInDungeon_(), 0.5, {
            "actionType": ActionSlotType.DESCEND,
            "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
            "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
            "seed": _random.randInt(1000),
            "width": 50,
            "height": 50
        });
        local pos = mEntityManager_.getPosition(en);
        pos.y -= 0.6;
        mEntityManager_.setEntityPosition(en, pos);
    }

    function findPosInDungeon_(){
        local roomId = mMapData_.weighted[_random.randIndex(mMapData_.weighted)];
        local targetRoom = mMapData_.rooms[roomId].foundPoints;
        local point = targetRoom[_random.randIndex(targetRoom)];

        local targetPos = Vec3( (point & 0xFFFF), 0, (point >> 16) & 0xFFFF );
        targetPos *= 5;

        return targetPos;
    }

    #Override
    function getMapData(){
        return mMapData_;
    }

};