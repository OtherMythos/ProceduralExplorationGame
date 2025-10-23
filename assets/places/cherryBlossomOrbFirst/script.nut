::PlaceScriptObject <- {

    function processDataPoint(world, pos, major, minor){

    }

    function appear(world, placeId, pos, node){
        world.mEntityFactory_.constructOrb(OrbId.IN_THE_CHERRY_BLOSSOM, pos);
    }

};