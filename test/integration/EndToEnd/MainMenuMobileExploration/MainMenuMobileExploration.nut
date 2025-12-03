_tIntegration("MainMenuMobileExploration", "Test to check the mobile main menu can go from startup to a gameplay session.", {
    //Testing a regression that was noticed when trying to close the game while at the map selection screen.
    "steps": [
        function(){
            ::_testHelper.generateSimpleSaves(1);
            ::_testHelper.setDefaultWaitFrames(20);
        },
        ::_testHelper.STEPS_WAIT_FOR_SPLASH_SCREEN,
        ::_testHelper.STEPS_CLOSE_TITLE_SCREEN,
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenuComplex");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore", 1);
        },
        function(){
            ::_testHelper.waitFrames(50);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Unlock");
            ::_testHelper.waitFrames(50);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore", 2);
        }

    ]
});