_tIntegration("MainMenuToCompleteExplorationThenRestart", "Move from the main menu to the exploration, complete it, return to the main menu and then try and explore again. Reproduces a bug when attempting to restart exploration.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::_testHelper.waitFrames(100);
            ::Base.mExplorationLogic.mCurrentWorld_.findAllRegions();
        },
        function(){
            ::_testHelper.waitFrames(300);
            ::Base.mExplorationLogic.gatewayEndExploration();
            ::_testHelper.queryWindowExists("ExplorationEndScreen");
        },
        function(){
            if(::_testHelper.getWidgetForText("Return to menu") != null){
                ::_testHelper.mousePressWidgetForText("Return to menu");
            }else{
                _testHelper.repeatStep();
            }
        },
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenu");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        ::_testHelper.STEPS_WAIT_FOR_MAP_GEN_COMPLETE,
        function(){
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});