::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationProgressBar <- class{
    mParentScreen_ = null;
    mWindow_ = null;
    mPanel_ = null;

    mWidth_ = 0;
    mHeight_ = 60;
    mPadding_ = 8;

    mOptionButtons_ = null;

    function exploreAgainButton(widget, action){
        mParentScreen_.mLogicInterface_.resetExploration();
    }

    function mainMenuButton(widget, action){
        ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
    }

    constructor(parentWin, parentScreen){
        mParentScreen_ = parentScreen;
        mWidth_ = _window.getWidth() * 0.9;

        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setSize(mWidth_, mHeight_);
        mWindow_.setClipBorders(0, 0, 0, 0);

        {
            mPanel_ = mWindow_.createPanel();
            mPanel_.setSize(100, 100);
            mPanel_.setPosition(mPadding_, mPadding_);
            mPanel_.setDatablock("gui/explorationProgressBar");
        }

        { //Create buttons
            local buttonLayout = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
            mOptionButtons_ = [];

            local buttonNames = ["Explore again", "Main Menu"]
            local buttonFunctions = [exploreAgainButton, mainMenuButton];
            foreach(c,i in buttonNames){
                local button = mWindow_.createButton();
                button.setText(i);
                button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
                button.setHidden(true);
                buttonLayout.addCell(button);
                button.setExpandVertical(true);
                button.setExpandHorizontal(true);
                button.setProportionHorizontal(1);
                mOptionButtons_.append(button);
            }

            buttonLayout.setMarginForAllCells(10, 10);
            buttonLayout.setSize(mWindow_.getSize());
            buttonLayout.layout();
        }

        setPercentage(0);
    }

    function setPercentage(percentage){
        //*2 for both sides.
        local actualWidth = mWidth_ - mPadding_ * 2;
        mPanel_.setSize(actualWidth * (percentage.tofloat() / 100.0), mHeight_ - mPadding_ * 2);
    }

    function showButtons(show){
        foreach(i in mOptionButtons_){
            i.setHidden(!show);
        }

        mPanel_.setHidden(show);
    }

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
    }
};