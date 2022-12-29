::ScreenManager.Screens[Screen.COMBAT_SCREEN].CombatPlayerDialog <- class{
    mWindow_ = null;
    mCombatBus_ = null;

    mCombatScenePanel_ = null;
    mCompositorId_ = null;

    constructor(parentWin, combatBus){
        mCombatBus_ = combatBus;
        combatBus.registerCallback(busCallback, this);

        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setMargin(5, 0);

        mCombatScenePanel_ = mWindow_.createPanel();
        mCombatScenePanel_.setPosition(0, 0);
    }

    function shutdown(){
        mCombatScenePanel_.setDatablock("unlitEmpty");
        shutdownCompositor_();
    }

    function shutdownCompositor_(){
        if(mCompositorId_ == null) return;
        ::CompositorManager.destroyCompositorWorkspace(mCompositorId_);
        mCompositorId_ = null;
    }

    function notifyResize(){
        local winSize = mWindow_.getSize();
        winSize = Vec2(winSize.y, winSize.y);
        mWindow_.setSize(winSize);
        mCombatScenePanel_.setSize(winSize);

        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture25Workspace", winSize, CompositorSceneType.COMBAT_PLAYER);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mCombatScenePanel_.setDatablock(datablock);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(1);
    }

    function busCallback(event, data){
        switch(event){
            // case CombatBusEvents.STATE_CHANGE:{
            //     _handleStateChange(data);
            //     break;
            // }
        }
    }
};