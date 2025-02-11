::PlaceScriptObject <- {

    function processDataPoint(world, pos, major, minor){

    }

    function appear(world, placeId, pos, node){
        local width = 2;
        local height = 2;
        local inv = array(width * height, null);
        inv[0] = ::Item(ItemId.BONE_MACE);
        inv[3] = ::Item(ItemId.SIMPLE_SWORD);
        world.mEntityFactory_.constructChestObjectInventory(pos, node.createChildSceneNode(), inv, width, height);
    }

};