::OverworldLogic <- {

    mWorld_ = null
    mParentSceneNode_ = null

    function setup(){

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
        mWorld_.update();
    }

    function shutdown(){
        mParentSceneNode_.destroyNodeAndChildren();
        mWorld_.shutdown();
    }

    function applyCameraDelta(delta){
        mWorld_.applyMovementDelta(delta);
    }

    function applyZoomDelta(delta){
        mWorld_.applyZoomDelta(delta);
    }

}