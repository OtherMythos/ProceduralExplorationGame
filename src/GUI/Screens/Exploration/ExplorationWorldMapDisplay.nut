::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].WorldMapDisplay <- class{

    mExplorationScenePanel_ = null;
    mCompositorId_ = null;

    constructor(parentWin){
        mExplorationScenePanel_ = parentWin.createPanel();
        mExplorationScenePanel_.setPosition(0, 0);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mExplorationScenePanel_);
        mExplorationScenePanel_.setExpandVertical(true);
        mExplorationScenePanel_.setExpandHorizontal(true);
        mExplorationScenePanel_.setProportionVertical(2);
    }

    function shutdownCompositor_(){
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function notifyResize(){
        local winSize = mExplorationScenePanel_.getSize();

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture30Workspace", winSize, CompositorSceneType.EXPLORATION);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mExplorationScenePanel_.setDatablock(datablock);
    }

    function getPosition(){
        return mExplorationScenePanel_.getPosition();
    }

    function getWorldPositionInScreenSpace(pos){
        local camera = ::CompositorManager.getCameraForSceneType(CompositorSceneType.EXPLORATION)
        local worldPos = camera.getWorldPosInWindow(pos);

        local winSize = mExplorationScenePanel_.getSize();
        local width = winSize.x / 2;
        local height = winSize.y / 2;
        local posX = width + (width * worldPos.x);
        local posY = height + (height * -worldPos.y);

        return mExplorationScenePanel_.getPosition() + Vec2(posX, posY);
    }
};