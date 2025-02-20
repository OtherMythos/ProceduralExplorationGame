::PlaceScriptObject <- {

    function processDataPointCreation(world, pos, major, minor, node){
        local triggerWorld = world.getTriggerWorld();
        local targetRadius = 4;

        if(major == 0){
            local teleData = null;
            if(minor == 0){
                teleData = {
                    "actionType": ActionSlotType.ENTER,
                    "worldType": WorldTypes.PROCEDURAL_DUNGEON_WORLD,
                    "dungeonType": ProceduralDungeonTypes.CATACOMB,
                    "seed": _random.randInt(1000),
                    "width": 50,
                    "height": 50
                };
            }

            local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, pos.x, pos.z, targetRadius, _COLLISION_PLAYER);
        }
        else if(major == 1){
            local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.READ_LORE, "TombstonePlaque", pos.x, pos.z, targetRadius, _COLLISION_PLAYER);
        }
    }

    function appear(world, placeId, pos, node){

    }

};