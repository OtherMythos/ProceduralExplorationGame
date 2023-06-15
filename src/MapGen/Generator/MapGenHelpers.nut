::MapGenHelpers <- {

    //TODO reduce some of the duplication in the actual map generator.
    function getLandmassForPos(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        printf("Testing %i %i", x, y);

        local buf = worldData.voxelBuffer;
        buf.seek((x + y * worldData.width) * 4);
        local landGroup = ((buf.readn('i') >> 24) & 0xFF);

        printf("land group %i", landGroup);
        return landGroup == 255 ? null : landGroup;
    }

    function getRandomPointOnLandmass(worldData, landmassId){
        printf("landmass %i", landmassId);
        local landmass = worldData.landData[landmassId];
        local point = findRandomPointInLandmass(worldData, landmass);
        local outPoint = Vec3(
            (point >> 16) & 0xFFFF, 0
            point & 0xFFFF);

        outPoint.z = -outPoint.z;
        printf("landmass %s", outPoint.tostring());
        return outPoint;
    }

    function findRandomPointInLandmass(worldData, landData){
        local randIndex = _random.randIndex(landData.coords);
        return landData.coords[randIndex];
    }

    function findRandomPointOnLand(worldData, start, radius){
        local offset = Vec3(0.5, 0, 0.5);
        for(local i = 0; i < 100; i++){
            local targetPos = start + (_random.randVec3() - offset) * radius;
            targetPos.y = 0;
            local landmassId = ::MapGenHelpers.getLandmassForPos(worldData, targetPos);
            if(landmassId == null) continue;
            return targetPos;
        }
        return null;
    }

};