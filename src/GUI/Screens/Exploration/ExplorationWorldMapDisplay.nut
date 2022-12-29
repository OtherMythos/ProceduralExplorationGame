::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].WorldMapDisplay <- class{
    mWindow_ = null;

    mExplorationScenePanel_ = null;
    mCompositorId_ = null;

    constructor(parentWin){
        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mExplorationScenePanel_ = mWindow_.createPanel();
        mExplorationScenePanel_.setPosition(0, 0);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(2);
    }

    function shutdownCompositor_(){
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function notifyResize(){
        local winSize = mWindow_.getSize();
        mExplorationScenePanel_.setSize(winSize);

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture30Workspace", winSize, CompositorSceneType.EXPLORATION);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mExplorationScenePanel_.setDatablock(datablock);
    }
};