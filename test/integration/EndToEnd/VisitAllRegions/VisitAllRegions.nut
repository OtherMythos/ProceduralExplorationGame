_tIntegration("VisitAllRegions", "Iterate all regions and teleport the player to each", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        //::_testHelper.setDefaultWaitFrames(20);

        ::regionStage <- 0;
    },

    "steps": [
        {
            "steps": ::_testHelper.STEPS_MAIN_MENU_TO_EXPLORATION_GAMEPLAY
        },
        {
            "steps": [
                function(){
                    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                    local mapData = currentWorld.getMapData();

                    local STEP = 10.0;

                    local stepX = (mapData.width / STEP).tointeger();
                    local stepY = (mapData.height / STEP).tointeger();
                    local currentX = (regionStage % STEP).tointeger();
                    local currentY = (regionStage / STEP).tointeger();

                    currentWorld.setPlayerPosition(currentX * stepX, -currentY * stepY);
                    ::regionStage++;

                    if(currentY > STEP){
                        _test.endTest();
                    }else{
                        ::_testHelper.repeatStep();
                    }
                }
            ]
        }
    ]
});