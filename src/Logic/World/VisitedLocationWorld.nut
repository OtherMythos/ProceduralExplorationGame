//TODO get rid of this.
::ExplorationCount <- 0;

::VisitedLocationWorld <- class extends ::World{

    mMapData_ = null;
    mTargetMap_ = null;
    mVoxTerrainMesh_ = null;

    constructor(targetMap){
        base.constructor();

        mTargetMap_ = targetMap;
    }

    function getWorldType(){
        return WorldTypes.VISITED_LOCATION_WORLD;
    }

    function setup(){
        base.setup();

        resetSession();
    }

    function resetSession(){
        base.resetSession();

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

    function getZForPos(pos){
        if(mMapData_ == null) return 0;

        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local height = mMapData_.voxHeight.data[x + y * mMapData_.width];

        return height * 0.4;
    }

    function getIsWaterForPosition(pos){
        return getZForPos(pos) == 0;
    }

    function createScene(){
        local targetNode = _scene.getRootSceneNode().createChildSceneNode();
        local path = "res://assets/maps/" + mTargetMap_ + "/scene.avscene";
        //_scene.insertSceneFile(path, targetNode);

        local parsedFile = _scene.parseSceneFile(path);
        local animData = _scene.insertParsedSceneFileGetAnimInfo(parsedFile, targetNode);

        local path = "res://assets/maps/" + mTargetMap_ + "/sceneAnimation.xml";
        _animation.loadAnimationFile(path);
        ::currentAnim <- _animation.createAnimation("sceneAnim", animData);

        printf("Loading scene file with path '%s'", path);

        //Parse the terrain information.
        local file = File();
        path = "res://build/assets/maps/" + mTargetMap_ + "/terrain.txt";
        file.open(path);
        local voxData = parseFileToData_(file);

        file = File();
        path = "res://build/assets/maps/" + mTargetMap_ + "/terrainBlend.txt";
        file.open(path);
        local colourData = parseFileToData_(file);

        voxeliseMapData_(voxData, colourData, targetNode);

        //TODO temporary for now.
        mMapData_ = {
            "voxHeight": voxData,
            "voxType": colourData,

            "width": voxData.width,
            "height": voxData.height,
        };

        local oceanNode = mParentNode_.createChildSceneNode();
        local oceanItem = _scene.createItem("plane");
        oceanItem.setRenderQueueGroup(30);
        oceanItem.setDatablock("oceanUnlit");
        oceanNode.attachObject(oceanItem);
        oceanNode.setScale(500, 500, 500)
        oceanNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        local character = mEntityFactory_.constructNPCCharacter();
        mActiveEnemies_.rawset(character.mEntity_.getId(), character);
        character.moveQueryZ(Vec3(100, 0, -50));
    }

    function voxeliseMapData_(mapData, colourData, targetNode){
        assert(mapData.width == colourData.width && mapData.height == colourData.height);

        local width = mapData.width;
        local height = mapData.height;
        local voxArray = array(mapData.width * mapData.height * mapData.greatest, null);
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                for(local i = 0; i < mapData.data[x + y * width]; i++){
                    voxArray[x + (y * width) + (i*width*height)] = colourData.data[x + y * width];
                }
            }
        }

        local vox = VoxToMesh(Timer(), 1 << 2, 0.4);
        //TODO get rid of this with the proper function to destory meshes.
        ::ExplorationCount++;
        local meshObj = vox.createMeshForVoxelData("visitedLocationWorld" + ::ExplorationCount, voxArray, width, height, mapData.greatest);
        mVoxTerrainMesh_ = meshObj;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(30);
        local landNode = targetNode.createChildSceneNode();
        landNode.attachObject(item);
        landNode.setScale(1, 1, 0.4);
        landNode.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        vox.printStats();
    }

    function parseFileToData_(file){
        local outArray = [];
        local height = 0;
        local width = 0;
        local greatest = 0;
        while(!file.eof()){
            local line = file.getLine();
            local vals = split(line, ",");
            local len = vals.len();
            if(len == 0) continue;
            width = len;
            foreach(i in vals){
                local intVal = i.tointeger();
                outArray.append(intVal);
                if(intVal > greatest){
                    greatest = intVal;
                }
            }
            height++;
        }


        return {
            "width": width,
            "height": height,
            "greatest": greatest,
            "data": outArray,
        }
    }

    function getMapData(){
        return mMapData_;
    }

    function checkForEnemyAppear(){
        //Stub to get enemies to stop spawning.
        return;
    }

};