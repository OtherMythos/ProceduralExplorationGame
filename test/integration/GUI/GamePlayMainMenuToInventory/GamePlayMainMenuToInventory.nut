_tIntegration("GamePlayMainMenuToInventory", "Switch to the inventory screen from the gameplay main menu multiple times.", {
    "steps": [
        function(){
            ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
            //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.INVENTORY_SCREEN, {"stats": ::Base.mPlayerStats, "disableBackground": true}));

            ::_testHelper.queryWindowExists("GameplayMainMenu");

            ::_testHelper.waitFrames(20);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Inventory");

            ::_testHelper.queryWindowExists("InventoryScreen");

            ::_testHelper.waitFrames(20);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Back");

            ::_testHelper.queryWindowExists("GameplayMainMenu");

            ::_testHelper.waitFrames(20);
        },
    ]
});