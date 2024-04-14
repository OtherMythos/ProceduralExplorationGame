_tIntegration("GamePlayMainMenuToInventory", "Switch to the inventory screen from the gameplay main menu multiple times.", {
    "start": function(){
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": {
        "repeat": 5,
        "steps": [
            function(){
                ::ScreenManager.transitionToScreen(Screen.GAMEPLAY_MAIN_MENU_SCREEN);

                ::_testHelper.queryWindowExists("GameplayMainMenu");
            },
            function(){
                ::_testHelper.mousePressWidgetForText("Inventory");

                ::_testHelper.queryWindowExists("InventoryScreen");
            },
            function(){
                ::_testHelper.mousePressWidgetForText("Back");

                ::_testHelper.queryWindowExists("GameplayMainMenu");
            }
        ]
    }
});