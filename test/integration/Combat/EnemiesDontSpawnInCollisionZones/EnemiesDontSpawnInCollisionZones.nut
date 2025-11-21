::_destroyEnemy <- function(enemy){
    local world = ::Base.mExplorationLogic.mCurrentWorld_;
    world.getEntityManager().destroyEntity(enemy.getEID(), EntityDestroyReason.LIFETIME);
}

_tIntegration("EnemiesDontSpawnInCollisionZones", "Check if the system attempts to spawn an enemy in an area that the enemy wouldn't be able to move, the spawn fails.", {
    "start": function(){
        ::_testHelper.setDefaultWaitFrames(20);
    },

    "steps": [
        function(){
            ::_testHelper.waitFrames(10);
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            //No colliders placed so far, so the enemy should spawn easily.
            local enemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(10, 0, 0));
            _test.assertNotEqual(null, enemy);

            _destroyEnemy(enemy);
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local collisionWorld = world.getCollisionDetectionWorld();

            local collisionDetectionPoint = collisionWorld.
                addCollisionPoint(10, 0, 2, 0xFF, _COLLISION_WORLD_ENTRY_SENDER);

            local enemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(10, 0, 0));
            _test.assertEqual(enemy, null);

            local secondEnemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(-10, 0, 0));
            _test.assertNotEqual(null, secondEnemy);

            _destroyEnemy(secondEnemy);

            //Remove the point at the end and check in the next step that there are no problems spawning enemies.
            collisionWorld.removeCollisionPoint(collisionDetectionPoint);
        },
        function(){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local collisionWorld = world.getCollisionDetectionWorld();

            //All should be placed fine.
            local enemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(10, 0, 0));
            _test.assertNotEqual(enemy, null);

            local secondEnemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(-10, 0, 0));
            _test.assertNotEqual(secondEnemy, null);

            _destroyEnemy(enemy);
            _destroyEnemy(secondEnemy);
        }
        //TODO check grid collision also.
    ]
});