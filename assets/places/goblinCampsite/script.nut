::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        local entityFactory = world.getEntityFactory();
        local triggerWorld = world.getTriggerWorld();


        world.createEnemyCheckCollision(EnemyId.GOBLIN, pos + Vec3(3, 0, 4));
        world.createEnemyCheckCollision(EnemyId.GOBLIN, pos + Vec3(-3, 0, 3));
        if(_random.randInt(0, 3) == 0){
            world.createEnemyCheckCollision(EnemyId.GOBLIN, pos + Vec3(-3, 0, -4));
        }
    }

};