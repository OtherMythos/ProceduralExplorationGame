::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        local entityFactory = world.getEntityFactory();
        local triggerWorld = world.getTriggerWorld();

        local spread = 7;
        for(local i = 0; i < 4 + _random.randInt(3); i++){
            local s = spread + _random.rand() * 10;
            local randDir = (_random.rand()*2-1) * PI;
            local dir = (Vec3(sin(randDir) * s, 0, cos(randDir) * s));
            local targetPos = pos + dir;
            local orientation = Quat(-PI/(_random.rand()*1.5+1), ::Vec3_UNIT_X);
            orientation *= Quat(_random.rand()*PI - PI/2, ::Vec3_UNIT_Y);
            local model = _random.randInt(4) == 0 ? "skeletonBody.voxMesh" : "skeletonHead.voxMesh";
            entityFactory.constructSimpleItem(node, model, targetPos, 0.15, null, null, 10, orientation);
        }

        world.createEnemy(EnemyId.DUST_MITE_WORKER, pos + Vec3(12, 0, 8));
        world.createEnemy(EnemyId.DUST_MITE_WORKER, pos + Vec3(-12, 0, 8));

        local teleData = {
            "actionType": ActionSlotType.DESCEND,
            "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
            "dungeonType": ProceduralDungeonTypes.DUST_MITE_NEST,
            "seed": _random.randInt(1000),
            "radius": 6,
            "width": 50,
            "height": 50
        };

        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, pos.x, pos.z, teleData.radius, _COLLISION_PLAYER);
    }

};