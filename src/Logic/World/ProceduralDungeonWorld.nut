//TODO get rid of this.
::ExplorationCount <- 0;

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

        createScene();
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

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

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

                local itemName = "DungeonFloor.mesh";
                local orientation = Quat();
                if(mask == 0){
                }else{
                    if(mask == 0x2) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x4) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    else if(mask == 0x8) orientation = Quat(0, 1, 0, 0);
                    itemName = "DungeonWall.mesh";

                    if((mask & (mask - 1)) != 0){
                        //Two bits are true meaning this is a corner.
                        itemName = "DungeonWallCorner.mesh";
                        if(mask == 0x3) orientation = Quat(0, sqrt(0.5), 0, sqrt(0.5));
                        if(mask == 0xA) orientation = Quat(0, 1, 0, 0);
                        if(mask == 0xC) orientation = Quat(0, -sqrt(0.5), 0, sqrt(0.5));
                    }
                }

                local item = _scene.createItem(itemName);
                item.setRenderQueueGroup(30);
                newNode.attachObject(item);
                newNode.setOrientation(orientation);
            }
        }
    }

    #Override
    function getMapData(){
        return mMapData_;
    }

};