_tIntegration("PlayerDeathFromAttack", "Test to check the player dies properly if attacked by something.", {
    "start": function(){
        ::_testHelper.clearAllSaves();
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        function(){
            ::_testHelper.waitFrames(10);
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            ::targetEnemy <- world.createEnemy(EnemyId.BEE_HIVE, Vec3(0, 0, 0));
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            world.performDirectionalAttack(Vec3(0, 0, 1));
            ::_testHelper.waitFrames(20);
        },
        function(){
            ::Base.mPlayerStats.setPlayerHealth(1);
        },
        function(){
            ::_testHelper.setQueryText("Return to menu");
        },
        ::_testHelper.STEPS_WAIT_FOR_WIDGET_WITH_TEXT,
        function(){
            ::_testHelper.waitFrames(100);
        },
    ]
});