_tIntegration("MainMenuToExploration", "Move from the first main menu screen to the initial gameplay.", {
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
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});