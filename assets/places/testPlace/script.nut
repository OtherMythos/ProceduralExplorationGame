::PlaceScriptObject <- {

    function processDataPointCreation(placeId, world, pos, major, minor, node){
        if(major == 0){
            local triggerWorld = world.getTriggerWorld();
            local targetRadius = 4;

            local teleData = {
                "actionType": ActionSlotType.ENTER,
                "worldType": WorldTypes.VISITED_LOCATION_WORLD,
                "mapName": "houseInterior"
            };

            if(minor == 0){
                teleData.mapName = "houseInterior";
            }
            else if(minor == 1){
                teleData.mapName = "houseInterior";
            }

            local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, pos.x, pos.z, targetRadius, _COLLISION_PLAYER);
        }
    }

    function processDataPointBecameVisible(world, pos, major, minor, node){
        if(major == 1){
            if(minor == 0){
                local newNPC = world.createNPCWithDialog(pos, "res://build/assets/dialog/test.dialog", 0, null);
            }
        }
    }

    function appear(world, placeId, pos, node){
    }

};