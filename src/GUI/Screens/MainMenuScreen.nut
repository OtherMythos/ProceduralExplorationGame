::ScreenManager.Screens[Screen.MAIN_MENU_SCREEN] = class extends ::Screen{

    function recreate(){
        mWindow_ = _gui.createWindow("MainMenuScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText(GAME_TITLE, false);
        layoutLine.addCell(title);

        title.sizeToFit(::drawable.x * 0.9);

        local buttonOptions = ["Play", "Help", "Quit to Desktop"];
        local buttonFunctions = [
            function(widget, action){
                ::ScreenManager.transitionToScreen(Screen.SAVE_SELECTION_SCREEN);
            },
            function(widget, action){
                ::ScreenManager.transitionToScreen(Screen.HELP_SCREEN);
            },
            function(widget, action){
                _shutdownEngine();
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

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(::drawable.x * 0.05, ::drawable.y * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y);
        layoutLine.layout();
    }

};