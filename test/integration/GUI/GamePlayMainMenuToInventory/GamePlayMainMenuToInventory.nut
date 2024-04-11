_tIntegration("GamePlayMainMenuToInventory", "Switch to the inventory screen from the gameplay main menu multiple times.", {
    "steps": {
        "repeat": 5,
        "steps": [
            function(){
                ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);

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
            }
        ]
    }
});