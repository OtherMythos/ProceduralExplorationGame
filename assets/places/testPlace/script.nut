::PlaceScriptObject <- {

    function processDataPoint(world, pos, major, minor){

    }

    function appear(world, placeId, pos, node){

        local newNPC = world.createNPCWithDialog(pos + Vec3(5, 0, 5), "res://build/assets/dialog/test.dialog", 0, null);
    }

};