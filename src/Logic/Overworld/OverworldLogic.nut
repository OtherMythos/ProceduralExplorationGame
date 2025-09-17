::OverworldLogic <- {

    mWorld_ = null
    mParentSceneNode_ = null

    mActiveCount_ = 0

    function requestSetup(){
        local active = isActive();
        mActiveCount_++;
        if(active) return;

        setup_();
    }

    function requestShutdown(){
        mActiveCount_--;
        if(isActive()) return;

        shutdown_();
    }

    function isActive(){
        return mActiveCount_ > 0;
    }

    function setup_(){

        print("Setting up overworld");

        mParentSceneNode_ = _scene.getRootSceneNode().createChildSceneNode();
        /*
        local node = mParentSceneNode_.createChildSceneNode();
        local item = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        node.attachObject(item);
        */
        //node.setScale(0.1, 0.1, 0.1);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.getParentNode().setPosition(0, 150, 300);
        camera.lookAt(300, 0, -300);

        camera.setFarClipDistance(2000);

        local preparer = ::OverworldPreparer();
        mWorld_ = ::Overworld(0, preparer);
        //local dummy = _gameCore.getDummyMapGen();
        local dummy = _gameCore.loadOverworld("overworld");
        local nativeData = dummy.data;
        local data = nativeData.explorationMapDataToTable();
        data.rawset("placeData", []);
        data.playerStart <- 0;
        mWorld_.setup();
        mWorld_.resetSession(data, nativeData);
    }

    function update(){
        if(!isActive()) return;
        mWorld_.update();
    }

    function shutdown_(){
        mParentSceneNode_.destroyNodeAndChildren();
        mWorld_.shutdown();

        print("Shutting down overworld");
    }

    function applyCameraDelta(delta){
        mWorld_.applyMovementDelta(delta);
    }

    function applyZoomDelta(delta){
        mWorld_.applyZoomDelta(delta);
    }

}