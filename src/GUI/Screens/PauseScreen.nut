
::ScreenManager.Screens[Screen.PAUSE_SCREEN] = class extends ::Screen{

    mActionSetId_ = null;

    buttonOptions = ["Resume", "Settings", "Return to Main Menu"];
    buttonFunctions = [
        function(widget, action){
            ::Base.mExplorationLogic.setGamePaused(false);
            closeScreen();
        },
        function(widget, action){
            ::ScreenManager.queueTransition(Screen.SETTINGS_SCREEN, null, 3);
        },
        function(widget, action){
            ::Base.mExplorationLogic.setGamePaused(false);
            ::Base.mExplorationLogic.shutdown();
            closeScreen();
            ::ScreenManager.queueTransition(::BaseHelperFunctions.getTargetMainMenu());
        }
    ];
    mButtons_ = null;

    function recreate(){
        mWindow_ = _gui.createWindow("PauseScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        createBackgroundScreen_();

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Paused", false);
        title.sizeToFit(::drawable.x * 0.9);
        title.setExpandHorizontal(true);
        layoutLine.addCell(title);

        mButtons_ = [];
        foreach(c,i in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
            if(c == 0) button.setFocus();
            mButtons_.append(button);
        }

        layoutLine.setMarginForAllCells(0, ::ScreenManager.calculateRatio(20));
        layoutLine.setPosition(::drawable.x * 0.05, 50);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.setHardMaxSize(::drawable.x * 0.9, ::drawable.y * 0.9);
        layoutLine.layout();

        //TODO rather than doing this in screens it would make more sense to have a system to manage it.
        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
    }

    function shutdown(){
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }

    function closeScreen(){
        ::ScreenManager.queueTransition(null, null, mLayerIdx);
        //::Base.mExplorationLogic.setGamePaused(false);
        ::Base.mExplorationLogic.unPauseExploration();
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED) || _input.getButtonAction(::InputManager.closePause, _INPUT_PRESSED)){
            if(::ScreenManager.isForefrontScreen(mLayerIdx)){
                closeScreen();
            }
        }
    }

}