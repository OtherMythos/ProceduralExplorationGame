_tIntegration("PlayerDeathPushedWorld", "Test to check the player death screen can be shown while a world is pushed", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            local data = {
                "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
                "dungeonType": ProceduralDungeonTypes.CATACOMB,
                "width": 50,
                "height": 50,
                "seed": 100
            };
            local worldInstance = ::Base.mExplorationLogic.createWorldInstance(WorldTypes.PROCEDURAL_DUNGEON_WORLD, data);
            ::Base.mExplorationLogic.pushWorld(worldInstance);
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