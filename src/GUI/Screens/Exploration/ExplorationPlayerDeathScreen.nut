::ScreenManager.Screens[Screen.PLAYER_DEATH_SCREEN] = class extends ::Screen{

    function setup(data){

        local winWidth = ::drawable.x * 0.8;
        local winHeight = ::drawable.y * 0.8;

        //Create a window to block inputs for when the popup appears.
        createBackgroundScreen_();

        mWindow_ = _gui.createWindow("PlayerDeathScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(::drawable.x * 0.1, ::drawable.y * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("You died!");
        title.setSize(winWidth, title.getSize().y);
        title.setTextColour(0, 0, 0, 1);
        layoutLine.addCell(title);

        //Add the buttons.
        local buttonOptions = ["Explore again", "Return to menu"];
        local buttonFunctions = [
            function(widget, action){
                ::Base.mExplorationLogic.resetExploration();
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            },
            function(widget, action){
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
                ::ScreenManager.queueTransition(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
                ::Base.mExplorationLogic.shutdown();
            }
        ];
        foreach(i,c in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(c);
            button.attachListenerForEvent(buttonFunctions[i], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
        }

        layoutLine.setSize(winWidth, winHeight);
        layoutLine.setPosition(0, 0);
        layoutLine.layout();
    }
}