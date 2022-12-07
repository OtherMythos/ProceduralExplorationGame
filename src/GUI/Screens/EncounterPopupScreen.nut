::ScreenManager.Screens[Screen.ENCOUNTER_POPUP_SCREEN] = class extends ::Screen{

    mCount_ = 0;
    mBackgroundColour_ = false;

    mBackgroundWindow_ = null;

    function setup(data){
        local winWidth = _window.getWidth() * 0.8;

        //Create a window to block inputs for when the popup appears.
        mBackgroundWindow_ = _gui.createWindow();
        mBackgroundWindow_.setSize(_window.getWidth(), _window.getHeight());
        mBackgroundWindow_.setVisualsEnabled(false);

        mWindow_ = _gui.createWindow();
        mWindow_.setSize(winWidth, _window.getHeight() * 0.333);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.333);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Encounter");
        title.setSize(winWidth, title.getSize().y);
        title.setTextColour(0, 0, 0, 1);

        mWindow_.setSize(winWidth, title.getSize().y + 10*2);

        setBackground(mBackgroundColour_);
    }

    function update(){
        mCount_++;
        if(mCount_ % 25 == 0){
            mBackgroundColour_ = !mBackgroundColour_;
            setBackground(mBackgroundColour_);
        }

        if(mCount_ >= 150){
            ::ScreenManager.transitionToScreen(null, null, 2);
            //TODO would need to generate some new combat data here for the new encounter.
            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.COMBAT_SCREEN, {"logic": ::Base.mCombatLogic}));
        }
    }

    function setBackground(background){
        if(background) mWindow_.setDatablock("gui/encounterWindowFirstColour");
        else mWindow_.setDatablock("gui/encounterWindowSecondColour");
    }

    function shutdown(){
        _gui.destroy(mWindow_);
        _gui.destroy(mBackgroundWindow_);
    }
}