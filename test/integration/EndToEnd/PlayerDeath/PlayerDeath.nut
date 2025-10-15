_tIntegration("PlayerDeath", "Test to check the player death screen can be shown and exploration then restarted.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::Base.mPlayerStats.setPlayerHealth(0);
            ::_testHelper.setQueryText("Return to menu");
        },
        ::_testHelper.STEPS_WAIT_FOR_WIDGET_WITH_TEXT,
        function(){
            ::_testHelper.mousePressWidgetForText(::_testHelper.getQueryText());
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