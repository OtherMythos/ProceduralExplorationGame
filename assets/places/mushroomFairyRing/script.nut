::PlaceScriptObject <- {

    function appear(world, placeId, pos, node){
        local entityFactory = world.getEntityFactory();

        local radius = 5.0;
        local mushroomCount = 8;

        for(local i = 0; i < mushroomCount; i++){
            local angle = (2.0*3.14159265359 * i) / mushroomCount;
            local offsetX = radius * ::cos(angle);
            local offsetZ = radius * ::sin(angle);
            local mushroomPos = pos + Vec3(offsetX, 0, offsetZ);

            world.placePlacedItem(PlacedItemId.MUSHROOM_1, mushroomPos);
        }
    }

};
