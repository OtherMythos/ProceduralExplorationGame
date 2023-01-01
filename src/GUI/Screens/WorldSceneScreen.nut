::ScreenManager.Screens[Screen.WORLD_SCENE_SCREEN] = class extends ::Screen{

    mCombatScenePanel_ = null;
    mCompositorId_ = null;

    function setup(data){
        mWindow_ = _gui.createWindow();
        local winSize = Vec2(_window.getWidth(), _window.getHeight());
        mWindow_.setSize(winSize);
        mWindow_.setPosition(0, 0);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mCombatScenePanel_ = mWindow_.createPanel();
        mCombatScenePanel_.setPosition(0, 0);
        mCombatScenePanel_.setSize(winSize);

        {
            local backToExploration = mWindow_.createButton();
            backToExploration.setText("Back up");
            backToExploration.attachListenerForEvent(function(widget, action){
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
            }, _GUI_ACTION_PRESSED, this);
        }

        setupCompositor();

        ::Base.setupWorld("testWorld");
    }

    function shutdown(){
        base.shutdown();
        ::Base.shutdownWorld();
    }

    function setupCompositor(){
        local compId = ::CompositorManager.createCompositorWorkspace("renderTexture50_60Workspace", mWindow_.getSize(), CompositorSceneType.WORLD_SCENE);
        local datablock = ::CompositorManager.getDatablockForCompositor(compId);
        mCompositorId_ = compId;
        mCombatScenePanel_.setDatablock(datablock);
    }
}