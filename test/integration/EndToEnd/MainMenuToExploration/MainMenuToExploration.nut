_tIntegration("MainMenuToExploration", "Move from the first main menu screen to the initial gameplay.", {
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
        }
    ]
});