enum OverworldStates{
    NONE,

    ZOOMED_OUT,
    ZOOMED_IN,

    MAX
};

::OverworldLogic <- {

    mWorld_ = null
    mParentSceneNode_ = null
    mCompositor_ = null
    mRenderableSize_ = null
    mStateMachine_ = null

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

    function requestState(state){
        mStateMachine_.setState(state);
    }

    function isActive(){
        return mActiveCount_ > 0;
    }

    function setup_(){

        print("Setting up overworld");

        mStateMachine_ = OverworldStateMachine();

        mParentSceneNode_ = _scene.getRootSceneNode().createChildSceneNode();
        /*
        local node = mParentSceneNode_.createChildSceneNode();
        local item = _gameCore.createVoxMeshItem("playerHead.voxMesh");
        item.setRenderQueueGroup(RENDER_QUEUE_EXPLORATION);
        node.attachObject(item);
        */
        //node.setScale(0.1, 0.1, 0.1);

        mRenderableSize_ = ::drawable * ::resolutionMult;
        setupCompositor_();

        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
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

    function getCompositorDatablock(){
        return ::CompositorManager.getDatablockForCompositor(mCompositor_);
    }

    function setRenderableSize(pos, size){
        mRenderableSize_ = size;
        if(!isActive()) return;
        //shutdownCompositor_();
        //setupCompositor_();
        //::CompositorManager.resizeCompositor(mCompositor_, size);

        local datablock = getCompositorDatablock();
        {
            local calcWidth = size.x / ::drawable.x;
            local calcHeight = size.y / ::drawable.y;

            local calcX = pos.x / ::drawable.x;
            local calcY = pos.y / ::drawable.y;

            local mAnimMatrix_ = [
                1, 0, 0, 0,
                0, 1, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1,
            ];

            mAnimMatrix_[0] = calcWidth;
            mAnimMatrix_[5] = calcHeight;
            mAnimMatrix_[3] = calcX;
            mAnimMatrix_[7] = calcY;
            datablock.setEnableAnimationMatrix(0, true);
            datablock.setAnimationMatrix(0, mAnimMatrix_);
        }
    }

    function shutdownCompositor_(){
        ::CompositorManager.destroyCompositorWorkspace(mCompositor_);
    }

    function setupCompositor_(){
        {
            local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
            local size = ::drawable * ::resolutionMult;
            _gameCore.setupCompositorDefs(size.x.tointeger(), size.y.tointeger());
        }
        mCompositor_ = ::CompositorManager.createCompositorWorkspace("renderWindowWorkspaceGameplayTexture", mRenderableSize_, CompositorSceneType.OVERWORLD, true);
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
::OverworldLogic.OverworldStateMachine <- class extends ::Util.SimpleStateMachine{
    mStates_ = array(OverworldStates.MAX);
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_OUT] = class extends ::Util.SimpleState{
    function start(data){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.OVERWORLD);
        camera.getParentNode().setPosition(0, 150, 300);
        camera.lookAt(300, 0, -300);
    }

    function update(data){

    }
};

::OverworldLogic.OverworldStateMachine.mStates_[OverworldStates.ZOOMED_IN] = class extends ::Util.SimpleState{
    function start(data){

    }

    function update(data){

    }
};