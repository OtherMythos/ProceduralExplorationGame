::ScreenManager.Screens[Screen.OTHER_MYTHOS_SPLASH_SCREEN] = class extends ::Screen{

    mCount_ = 0;

    function recreate(){
        mWindow_ = _gui.createWindow("OtherMythosSplashScreen");
        mWindow_.setSize(::drawable);
        //mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinBlack");


        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        local fontScale = mobile ? 2.0 : 6.0;
        local panelSize = mobile ? 75 : 200;

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * fontScale);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("OtherMythos");
        local titleCentre = mWindow_.getSize() / 2;
        titleCentre.x += panelSize/2;
        title.setCentre(titleCentre);

        local panel = mWindow_.createPanel();
        panel.setSize(panelSize, panelSize);
        local panelCentre = title.getCentre();
        panelCentre.x -= title.getSize().x/2 + panelSize/2 + panelSize * 0.1;
        panel.setCentre(panelCentre);
        panel.setDatablock("OtherMythosLogo");

        //title.setMargin(20, 20);

        //Ensure the logo is fully loaded before showing anything.
        _graphics.waitForStreamingCompletion();
    }


    function update(){
        mCount_++;
        if(mCount_ >= 120){
            //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
            ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
        }
    }
};