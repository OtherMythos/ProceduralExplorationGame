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
    function getDefaultAmbientModifier(){
        return Vec3(0.25, 0.25, 0.25);
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

        //Update the minimap direction indicator via event
        local cameraDir = getCameraDirection();
        _event.transmit(Event.MINIMAP_CAMERA_DIRECTION_CHANGED, {
            "dirX": cameraDir.x,
            "dirY": cameraDir.y
        });
    }

    #Override
    function processWorldCurrentChange_(current){
        if(mParentNode_ != null) mParentNode_.setVisible(current);
    }

    #Override
    function processWorldActiveChange_(active){
        if(active){
            resetAtmosphereToDefaults();
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
        foreach(pos in mMapData_.objectPositions.enemies){
            local scaledPos = pos * mWorldScaleSize_ + mOffset_;
            createEnemy(enemyType, scaledPos);
        }
    }

    function createScene(){
        local gridPlacer = ::TileGridPlacer(getWallMeshes(), mWorldScaleSize_);
        local gridNode = gridPlacer.insertGridToScene(mParentNode_, mMapData_.resolvedTiles, mMapData_.width, mMapData_.height);
        gridNode.setPosition(mOffset_);

        //Place some decorations around the dungeon
        foreach(decoration in mMapData_.objectPositions.decorations){
            local targetPos = decoration.pos * mWorldScaleSize_ + mOffset_;

            local orientation = Quat(-PI/(decoration.orientation.rotX), ::Vec3_UNIT_X);
            orientation *= Quat(decoration.orientation.rotY, ::Vec3_UNIT_Y);
            local model = decoration.orientation.isSkeletonBody ? "skeletonBody.voxMesh" : "skeletonHead.voxMesh";
            mEntityFactory_.constructSimpleItem(mParentNode_, model, targetPos, 0.25, null, null, 10, orientation);
        }

        local chestPos = mMapData_.objectPositions.chest * mWorldScaleSize_ + mOffset_;
        mEntityFactory_.constructChestObject(chestPos);

        local ladderUpPos = mMapData_.objectPositions.ladderUp * mWorldScaleSize_ + mOffset_;
        mEntityFactory_.constructSimpleTeleportItem(mParentNode_, "ladderUp.voxMesh", ladderUpPos, 0.5, {
            "actionType": ActionSlotType.ASCEND,
            "renderQueue": RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY,
            "popWorld": true
        });

        local ladderDownPos = mMapData_.objectPositions.ladderDown * mWorldScaleSize_ + mOffset_;
        local en = mEntityFactory_.constructSimpleTeleportItem(mParentNode_, "ladderDown.voxMesh", ladderDownPos, 0.5, {
            "actionType": ActionSlotType.DESCEND,
            "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
            "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
            "renderQueue": RENDER_QUEUE_EXPLORATION_SHADOW_VISIBILITY,
            "seed": _random.randInt(1000),
            "width": 50,
            "height": 50
        });
        local pos = mEntityManager_.getPosition(en);
        pos.y -= 0.6;
        mEntityManager_.setEntityPosition(en, pos);
    }


    #Override
    function getMapData(){
        return mMapData_;
    }

};