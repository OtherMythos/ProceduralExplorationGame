_tIntegration("MainMenuMobileExplorationThenShutdown", "Test to check the mobile main menu allows switching to the exploration screen then shutting down the system.", {
    //Testing a regression that was noticed when trying to close the game while at the map selection screen.
    "steps": [
        function(){
            ::_testHelper.generateSimpleSaves(1);
            ::_testHelper.setDefaultWaitFrames(20);
        },
        ::_testHelper.STEPS_WAIT_FOR_SPLASH_SCREEN,
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenuComplex");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore", 1);
        },
        function(){
            ::ScreenManager.shutdown();
        }

    ]
});