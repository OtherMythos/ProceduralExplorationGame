::ExplorationCount <- 0;
::ExplorationSceneLogic <- class{

    mParentNode_ = null;
    mWorldData_ = null;
    mVoxMesh_ = null;

    constructor(){
    }

    function setup(){
        createScene();
        voxeliseMap();
    }

    function shutdown(){
        if(mParentNode_) mParentNode_.destroyNodeAndChildren();
        if(mVoxMesh_ == null){
        }

        mParentNode_ = null;
    }

    function resetExploration(worldData){
        shutdown();
        mWorldData_ = worldData;
        setup();
    }

    function voxeliseMap(){
        assert(mWorldData_ != null);
        local width = mWorldData_.width;
        local height = mWorldData_.height;
        local depth = 40;
        local voxData = array(width * height * depth, null);
        local buf = mWorldData_.voxelBuffer;
        buf.seek(0);
        local voxVals = [
            2, 112, 0, 192
        ]
        for(local y = 0; y < height; y++){
            for(local x = 0; x < width; x++){
                local vox = buf.readn('i')
                local voxFloat = (vox & 0xFF).tofloat();
                local altitude = ((voxFloat / 0xFF) * depth).tointeger();
                local voxelMeta = (vox >> 8) & 0x7F;
                if(voxFloat <= mWorldData_.seaLevel) voxelMeta = 3;
                for(local i = 0; i < altitude; i++){
                    voxData[x + (y * width) + (i*width*height)] = voxVals[voxelMeta];
                }
            }
        }
        local vox = VoxToMesh(1 << 2);
        //TODO get rid of this with the proper function to destory meshes.
        ::ExplorationCount++;
        local meshObj = vox.createMeshForVoxelData("worldVox" + ::ExplorationCount, voxData, width, height, depth);
        mVoxMesh_ = meshObj;

        local item = _scene.createItem(meshObj);
        item.setRenderQueueGroup(30);
        mParentNode_.attachObject(item);
        mParentNode_.setOrientation(Quat(-sqrt(0.5), 0, 0, sqrt(0.5)));

        local stats = vox.getStats();
        printf("Stats %i", stats.numTris);
    }


    function updatePercentage(percentage){
        if(_input.getMouseButton(0)){
            local width = _window.getWidth();
            local height = _window.getHeight();

            local posX = _input.getMouseX().tofloat() / width;
            local posY = _input.getMouseY().tofloat() / height;

            local dir = (Vec2(posX, posY) - Vec2(0.5, 0.5));
            dir.normalise();
            dir /= 2;

            {
                local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
                assert(camera != null);
                local parentNode = camera.getParentNode();
                parentNode.move(Vec3(dir.x, 0, dir.y));
            }
        }
    }

    function createScene(){
        mParentNode_ = _scene.getRootSceneNode().createChildSceneNode();

        {
            local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
            assert(camera != null);
            local parentNode = camera.getParentNode();
            parentNode.setPosition(0, 60, 90);
            camera.lookAt(0, 0, 0);
        }
    }

    function getFoundPositionForItem(item){
        return Vec3(0, 0, 0);
    }
    function getFoundPositionForEncounter(item){
        return Vec3(0, 0, 0);
    }
};