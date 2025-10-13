::ProceduralDungeonWorld <- class extends ::World{

    mMapData_ = null;
    mVoxMesh_ = null;

    mOffset_ = Vec3(3, 0, 3);

    constructor(worldId, preparer){
        base.constructor(worldId, preparer);
        mWorldScaleSize_ = 5;
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
    function getDefaultSkyColour(){
        return ::Vec3_ZERO;
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

        _gameCore.setupCollisionDataForWorld(mCollisionDetectionWorld_, mMapData_.vals, mMapData_.width, mMapData_.height);

        createScene();
        spawnEnemies();

        local targetPos = mMapData_.playerStart;
        local pos = Vec3(targetPos & 0xFFFF, 0, (targetPos >> 16) & 0xFFFF);
        pos *= mWorldScaleSize_;
        pos.y = getZForPos(pos);
        if(mPlayerEntry_.checkPositionCollides(pos)){
            throw "Player trapped in dungeon wall.";
        }
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

        mSkyAnimator_.setSkyColour(getDefaultSkyColour());
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

    function enemyTypeSpawn_(){
        switch(mMapData_.dungeonType){
            case ProceduralDungeonTypes.DUST_MITE_NEST:
                return EnemyId.DUST_MITE_WORKER;
            case ProceduralDungeonTypes.CATACOMB:
            default:
                return EnemyId.SKELETON;
        }
    }

    function spawnEnemies(){
        local enemyType = enemyTypeSpawn_();
        for(local i = 0; i < 3 + _random.randInt(3); i++){
            createEnemy(enemyType, findPosInDungeon_());
        }
    }

    function createScene(){
        local gridPlacer = ::TileGridPlacer(getWallMeshes(), mWorldScaleSize_);
        local gridNode = gridPlacer.insertGridToScene(mParentNode_, mMapData_.resolvedTiles, mMapData_.width, mMapData_.height);
        gridNode.setPosition(mOffset_);

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
        targetPos += mOffset_;

        return targetPos;
    }

    #Override
    function getMapData(){
        return mMapData_;
    }

};