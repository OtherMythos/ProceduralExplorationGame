_tIntegration("MainMenuToExplorationWithSaveSelection", "Move from the main menu through to the exploration screen, selecting a save on the way.", {
    "start": function(){
        ::_testHelper.generateSimpleSaves(5);
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
            ::_testHelper.mousePressWidgetForText("generated save 1");
        },
        function(){
            ::_testHelper.mousePressWidgetForText("Explore");
        },
        function(){
            ::_testHelper.queryWindowExists("ExplorationScreen");
        }
    ]
});