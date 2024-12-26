_tIntegration("MainMenuToExplorationDungeon", "Begin an exploration, start pushing worlds and check they can all be popped succesfully", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
        ::count <- 0;
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        function(){
            ::_testHelper.waitFrames(100);
            ::Base.mExplorationLogic.mCurrentWorld_.findAllRegions();
        },
        {
            "repeat": 5,
            "steps": [
                function(){
                    ::_testHelper.waitFrames(50);
                    local data = {
                        "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
                        "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
                        "width": 50,
                        "height": 50
                    };
                    local worldInstance = ::Base.mExplorationLogic.createWorldInstance(WorldTypes.PROCEDURAL_DUNGEON_WORLD, data);
                    ::Base.mExplorationLogic.pushWorld(worldInstance);
                },
                function(){
                    ::_testHelper.waitFrames(50);
                    ::Base.mExplorationLogic.mCurrentWorld_.createEnemyFromPlayer(1, 5);
                }
            ]
        },
        {
            "repeat": 5,
            "steps": [
                function(){
                    ::_testHelper.waitFrames(50);
                    ::Base.mExplorationLogic.popWorld();
                }
            ]
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