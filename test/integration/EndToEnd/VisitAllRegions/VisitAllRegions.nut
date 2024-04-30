_tIntegration("VisitAllRegions", "Iterate all regions and teleport the player to each", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);

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
        //TODO separate all the above stuff off at some point.
        {
            //TODO make it possible to request a single repeat at a time.
            "repeat": 500,
            "steps": [
                function(){
                    _testHelper.waitFrames(30);

                    local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                    local mapData = currentWorld.getMapData();

                    //local region = mapData.regionData[regionStage];
                    //currentWorld.setPlayerPosition(region.seedX, -region.seedY);

                    local region = mapData.regionData[regionStage];
                    print("Moving to region idx " + regionStage);
                    currentWorld.setPlayerPosition(region.seedX, -region.seedY);
                    ::regionStage++;
                    if(regionStage >= mapData.regionData.len()){
                        _test.endTest();
                    }
                }
            ]
        }
    ]
});