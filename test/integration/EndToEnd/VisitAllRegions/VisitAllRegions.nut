_tIntegration("VisitAllRegions", "Iterate all regions and teleport the player to each", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        //::_testHelper.setDefaultWaitFrames(20);

        ::regionStage <- 0;
    },

    "steps": [
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
            local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
            if(!currentWorld.isActive()){
                ::_testHelper.repeatStep();
            }
        },
        //TODO separate all the above stuff off at some point.
        {
            "repeat": 500,
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
                    }
                }
            ]
        }
    ]
});