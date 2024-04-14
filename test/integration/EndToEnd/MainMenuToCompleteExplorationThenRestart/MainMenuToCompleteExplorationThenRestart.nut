_tIntegration("MainMenuToCompleteExplorationThenRestart", "Move from the main menu to the exploration, complete it, return to the main menu and then try and explore again. Reproduces a bug when attempting to restart exploration.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
    },

    "steps": [
        function(){
            ::_testHelper.queryWindowExists("MainMenuScreen");
            ::_testHelper.waitFrames(20);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Play");
            ::_testHelper.queryWindowExists("SaveSelectionScreen");
            ::_testHelper.waitFrames(20);
        },
        function(){
            ::_testHelper.mousePressWidgetForText("new save");
            ::_testHelper.waitFrames(20);

            local screen = ::ScreenManager.getScreenForLayer(1);
            screen.mEditBox_.setText("test");
            ::_testHelper.mousePressWidgetForText("confirm");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.queryWindowExists("ExplorationScreen");
        },
        function(){
            ::_testHelper.waitFrames(300);
            ::Base.mExplorationLogic.gatewayEndExploration();
            ::_testHelper.queryWindowExists("ExplorationEndScreen");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.mousePressWidgetForText("Return to menu");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.queryWindowExists("GameplayMainMenu");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        function(){
            ::_testHelper.waitFrames(20);
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});