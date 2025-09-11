::OverworldLogic <- {

    mParentSceneNode_ = null

    function setup(){

        mParentSceneNode_ = _scene.getRootSceneNode().createChildSceneNode();
        local node = mParentSceneNode_.createChildSceneNode();
        local item = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        node.attachObject(item);
        //node.setScale(0.1, 0.1, 0.1);

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.getParentNode().setPosition(0, 0, 50);
        camera.lookAt(0, 0, 0);
    }

    function shutdown(){
        mParentSceneNode_.destroyNodeAndChildren();
    }

}