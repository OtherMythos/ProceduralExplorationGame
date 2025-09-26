_tIntegration("MainMenuToExplorationMobile", "Test the exploration mobile interface", {
    "steps": [
        function(){
            ::_testHelper.generateSimpleSaves(5);
            ::_testHelper.setDefaultWaitFrames(20);
        },
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenuComplex");
            ::_testHelper.waitFrames(30);
        },
        function(){
            //::_testHelper.mousePressWidgetForText("Explore");
            ::_testHelper.waitFrames(30);

            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
        },
        ::_testHelper.STEPS_WAIT_FOR_MAP_GEN_COMPLETE
        function(){
            ::_testHelper.waitFrames(30);
        },
        function(){
            _test.endTest();
        }

    ]
});