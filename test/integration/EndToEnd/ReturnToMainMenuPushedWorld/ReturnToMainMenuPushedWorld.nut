_tIntegration("ReturnToMainMenuPushedWorld", "Begin an exploration, start pushing worlds and check they can all be popped succesfully", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(10);
        ::count <- 0;
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::Base.mExplorationLogic.mCurrentWorld_.findAllRegions();
        },
        function(){
            local data = {
                "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
                "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
                "width": 50,
                "height": 50,
                "seed": 10
            };
            local worldInstance = ::Base.mExplorationLogic.createWorldInstance(WorldTypes.PROCEDURAL_DUNGEON_WORLD, data);
            ::Base.mExplorationLogic.pushWorld(worldInstance);
        },
        function(){
            ::Base.mExplorationLogic.shutdown();
            ::ScreenManager.queueTransition(Screen.GAMEPLAY_MAIN_MENU_SCREEN);
        },
        function(){
            ::_testHelper.queryWindowExists("GameplayMainMenu");
        }
    ]
});