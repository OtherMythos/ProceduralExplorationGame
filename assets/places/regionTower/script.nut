::PlaceScriptObject <- {

    function processDataPointCreation(placeId, world, pos, major, minor, node){
        if(major == 1){
            if(minor == 0){
                local triggerWorld = world.getTriggerWorld();
                local targetRadius = 4;

                local towerId = 0;
                switch(placeId){
                    case PlaceId.REGION_TOWER_1:{
                        towerId = 0;
                        break;
                    }
                    case PlaceId.REGION_TOWER_2:{
                        towerId = 1;
                        break;
                    }
                    case PlaceId.REGION_TOWER_3:{
                        towerId = 2;
                        break;
                    }
                }

                local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.ACTIVATE_TOWER, towerId, pos.x, pos.z, 8, _COLLISION_PLAYER);
            }
        }
    }

};