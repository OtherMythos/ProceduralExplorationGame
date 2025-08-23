::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        local triggerWorld = world.getTriggerWorld();
        local collisionPoint = triggerWorld.addCollisionSender(CollisionWorldTriggerResponses.OVERWORLD_VISITED_PLACE, 0, pos.x, pos.z, 4, _COLLISION_PLAYER);
    }

};