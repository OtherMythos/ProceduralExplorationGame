
::ScreenManager.Screens[Screen.PAUSE_SCREEN] = class extends ::Screen{

    function recreate(){
        mWindow_ = _gui.createWindow("PauseScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        createBackgroundScreen_();

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Paused", false);
        title.sizeToFit(::drawable.x * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        local buttonOptions = ["Resume", "Settings", "Return to Main Menu"];
        local buttonFunctions = [
            function(widget, action){
                ::Base.mExplorationLogic.setGamePaused(true);
                closeScreen();
            },
            function(widget, action){
                ::ScreenManager.queueTransition(Screen.SETTINGS_SCREEN, null, 3);
            },
            function(widget, action){
                ::Base.mExplorationLogic.setGamePaused(false);
                ::Base.mExplorationLogic.shutdown();
                closeScreen();
                ::ScreenManager.queueTransition(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
            }
        ]

        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
        }

        layoutLine.setMarginForAllCells(0, ::ScreenManager.calculateRatio(20));
        layoutLine.setPosition(::drawable.x * 0.05, 50);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.setHardMaxSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.layout();

        //TODO rather than doing this in screens it would make more sense to have a system to manage it.
        ::InputManager.setActionSet(InputActionSets.MENU);
    }

    function shutdown(){
        base.shutdown();
        ::InputManager.setActionSet(InputActionSets.EXPLORATION);
    }

    function closeScreen(){
        ::ScreenManager.queueTransition(null, null, mLayerIdx);
        ::Base.mExplorationLogic.setGamePaused(false);
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED) && ::ScreenManager.isForefrontScreen(mLayerIdx)){
            closeScreen();
        }
    }

}