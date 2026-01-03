::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        world.getEntityFactory().constructDeepHoleEntity(pos, "res://build/assets/places/deepHole/deepHole.dialog", 0, 4.0);
    }

};
