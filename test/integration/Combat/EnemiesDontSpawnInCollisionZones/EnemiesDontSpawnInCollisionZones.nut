::_destroyEnemy <- function(enemy){
    local world = ::Base.mExplorationLogic.mCurrentWorld_;
    world.getEntityManager().destroyEntity(enemy.getEID(), EntityDestroyReason.LIFETIME);
}

_tIntegration("EnemiesDontSpawnInCollisionZones", "Check if the system attempts to spawn an enemy in an area that the enemy wouldn't be able to move, the spawn fails.", {
    "start": function(){
        ::_testHelper.setDefaultWaitFrames(5);
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
        },
        function(){
            //Setup some collision grid data and try and spawn some enemies in a collided place.
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local collisionWorld = world.getCollisionDetectionWorld();

            local enemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(10, 0, 0));
            _test.assertNotEqual(enemy, null);

            local collisionData = array(100*100, true);
            _gameCore.setupCollisionDataForWorld(collisionWorld, collisionData, 100, 100);

            local secondEnemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(10, 0, 0));
            _test.assertEqual(secondEnemy, null);

            _destroyEnemy(enemy);
        },
        function(){
            //Setup some more permissive collision data and check some spawns can still be succesful.
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            local collisionWorld = world.getCollisionDetectionWorld();

            local collisionData = array(100*100, false);
            for(local y = 0; y < 100; y++){
                for(local x = 0; x < 100; x++){
                    collisionData[x + y * 100] = (x < 50 ? 1 : false);
                }
            }
            _gameCore.setupCollisionDataForWorld(collisionWorld, collisionData, 100, 100);

            local enemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(0, 0, 0) * 5);
            _test.assertNotEqual(enemy, null);

            local secondEnemy = world.createEnemyCheckCollision(EnemyId.GOBLIN, Vec3(55, 0, 0) * 5);
            _test.assertEqual(secondEnemy, null);

            _destroyEnemy(enemy);
        },
    ]
});