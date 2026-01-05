::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        world.createNPCWithDialog(pos, "res://build/assets/places/pilgrim/pilgrim.dialog", 0, null);
    }

};
