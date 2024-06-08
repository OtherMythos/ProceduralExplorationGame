_tStress("CreateDestroyEnemies", "Setup a world then create and spawn enemies and distractions over time.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);

        ::createdEnemies <- [];
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
        {
            "repeat": 500,
            "steps": [
                function(){
                    _testHelper.waitFrames(2);
                    local world = ::Base.mExplorationLogic.mCurrentWorld_;
                    local mapData = world.getMapData();

                    local createdEnemy = world.createEnemy(1, Vec3(mapData.width * _random.rand(), 0, -mapData.height * _random.rand()));

                    ::createdEnemies.append(createdEnemy);

                    if(::createdEnemies.len() > 20){
                        local index = _random.randIndex(::createdEnemies);

                        local enemy = ::createdEnemies[index];
                        world.getEntityManager().destroyEntity(enemy.getEID());

                        ::createdEnemies.remove(index);
                    }
                }
            ]
        }
    ]
});