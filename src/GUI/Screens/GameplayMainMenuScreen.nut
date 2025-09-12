::ScreenManager.Screens[Screen.GAMEPLAY_MAIN_MENU_SCREEN] = class extends ::Screen{

    function recreate(){
        mWindow_ = _gui.createWindow("GameplayMainMenu");
        mWindow_.setSize(::drawable.x, ::drawable.y);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setText("Main Menu", false);
        title.sizeToFit(::drawable.x * 0.9);
        layoutLine.addCell(title);

        local buttonOptions = [
            "Explore",
            "Inventory",
            "Quit to Desktop"
            //"Visit"
        ];
        local buttonFunctions = [
            function(widget, action){
                print("Explore");
                //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.GAMEPLAY_MAIN_MENU_COMPLEX_SCREEN, {"logic": ::Base.mExplorationLogic}));
            },
            function(widget, action){
                print("Inventory");
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, {"stats": ::Base.mPlayerStats, "disableBackground": true}));
            },
            function(widget, action){
                _shutdownEngine();
            }
            /*
            function(widget, action){
                print("Visit");
                ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.VISITED_PLACES_SCREEN, {"stats": ::Base.mPlayerStats}));
            }
            */
        ]

        foreach(c,i in buttonOptions){
            local button = mWindow_.createButton();
            button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
            button.setText(i);
            button.setSize(::drawable.x * 0.9, button.getSize().y * 1.5);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            button.setExpandHorizontal(true);
            button.setMinSize(0, 100);
            layoutLine.addCell(button);
            if(c==0) button.setFocus();
        }

        layoutLine.setMarginForAllCells(0, 20);
        layoutLine.setPosition(::drawable.x * 0.05, ::drawable.y * 0.1);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(::drawable.x * 0.9, ::drawable.y);
        layoutLine.layout();
    }

    function update(){

    }
};