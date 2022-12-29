::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].WorldMapDisplay <- class{
    mWindow_ = null;

    constructor(parentWin){
        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);

        local title = mWindow_.createLabel();
        title.setText("Exploration map");
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(2);
    }
};