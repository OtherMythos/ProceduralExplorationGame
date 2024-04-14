_tIntegration("MainMenuToCompleteExplorationThenRestart", "Move from the main menu to the exploration, complete it, return to the main menu and then try and explore again. Reproduces a bug when attempting to restart exploration.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        function(){
            ::_testHelper.queryWindowExists("MainMenuScreen");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Play");
            ::_testHelper.queryWindowExists("SaveSelectionScreen");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("new save");

            local screen = ::ScreenManager.getScreenForLayer(1);
            screen.mEditBox_.setText("test");
            ::_testHelper.mousePressWidgetForText("confirm");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        function(){
            ::_testHelper.queryWindowExists("ExplorationScreen");
        },
        function(){
            ::_testHelper.waitFrames(300);
            ::Base.mExplorationLogic.gatewayEndExploration();
            ::_testHelper.queryWindowExists("ExplorationEndScreen");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Return to menu");
        },
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenu");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        function(){
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});