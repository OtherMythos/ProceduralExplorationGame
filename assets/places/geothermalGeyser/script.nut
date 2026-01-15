::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        world.getEntityFactory().constructGeyser(pos + Vec3(0.5, 0, -0.5));
    }

};
