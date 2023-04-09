::ScreenManager.Screens[Screen.EXPLORATION_TEST_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mTestRenderIcon_ = null;
    mMapDisplay_ = null;

    mExplorationLogic_ = null;

    function setup(data){
        mExplorationLogic_ = data.logic;

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local layout = _gui.createLayoutLine();
        mMapDisplay_ = ::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].WorldMapDisplay(mWindow_);
        layout.setSize(mWindow_.getSize());
        //layout.addCell(mMapDisplay_);
        mMapDisplay_.addToLayout(layout);

        layout.layout();
        mMapDisplay_.notifyResize();

        mExplorationLogic_.resetExploration();
        //mExplorationLogic_.setup();
    }

    function update(){
        mExplorationLogic_.tickUpdate();
    }
};