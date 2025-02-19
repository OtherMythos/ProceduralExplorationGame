::PlaceScriptObject <- {

    function processDataPoint(world, pos, major, minor, node){
        if(major == 0){
            if(minor == 1){

                local triggerWorld = world.getTriggerWorld();
                local targetRadius = 4;
                local teleData = {
                    "actionType": ActionSlotType.ENTER,
                    "worldType": WorldTypes.VISITED_LOCATION_WORLD,
                    "radius": 6,
                    "mapName": "houseInterior"
                };
                local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.REGISTER_TELEPORT_LOCATION, teleData, pos.x, pos.z, targetRadius, _COLLISION_PLAYER);

            }
        }
    }

    function appear(world, placeId, pos, node){

        local newNPC = world.createNPCWithDialog(pos + Vec3(5, 0, 5), "res://build/assets/dialog/test.dialog", 0, null);
    }

};