_tIntegration("EnemiesChasePlayer", "Check that if in close proximity to the player, enemies will chase them.", {
    "start": function(){
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        function(){
            ::_testHelper.waitFrames(10);
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            ::targetEnemy <- world.createEnemy(EnemyId.GOBLIN, Vec3(10, 0, 0));
        },
        function(){
            local enemyPos = ::targetEnemy.getPosition();
            //Check the enemy gets close to the player.
            if(enemyPos.x <= ::EntityTargetManager.TARGET_DISTANCE){
                _test.endTest();
            }else{
                ::_testHelper.repeatStep();
            }
        }
    ]
});