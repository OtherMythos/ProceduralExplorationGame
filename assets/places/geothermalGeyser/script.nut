::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        world.getEntityFactory().constructGeyser(pos);
    }

};
