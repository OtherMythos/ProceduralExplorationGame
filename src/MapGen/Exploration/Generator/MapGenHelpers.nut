::MapGenHelpers <- {

    //TODO reduce some of the duplication in the actual map generator.
    function getLandmassForPos(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local buf = worldData.voxelBuffer;
        buf.seek((x + y * worldData.width) * 4);
        local landGroup = ((buf.readn('i') >> 24) & 0xFF);

        return landGroup == 255 ? null : landGroup;
    }

    function getAltitudeForPosition(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local voxBuff = worldData.voxelBuffer;
        voxBuff.seek((x + y * worldData.width) * 4);
        local val = voxBuff.readn('i');
        return val & 0xFF;
    }
    function getIsWaterForPosition(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local voxBuff = worldData.voxelBuffer;
        voxBuff.seek((x + y * worldData.width) * 4);
        local val = voxBuff.readn('i');
        if(val & 0xFF){
            if(val <= worldData.seaLevel) return true;
        }
        if((val >> 8) & MapVoxelTypes.RIVER) return true;

        return false;
    }
    function getRegionForData(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local voxBuff = worldData.secondaryVoxBuffer;
        voxBuff.seek((x + y * worldData.width) * 4);
        local val = ((voxBuff.readn('i') >> 8) & 0xFF);
        return val;
    }

    function getTraverseTerrainForPosition(worldData, pos){
        return getIsWaterForPosition(worldData, pos) ? EnemyTraversableTerrain.WATER : EnemyTraversableTerrain.LAND;
    }

    function getWaterGroupForPos(worldData, pos){
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        local buf = worldData.voxelBuffer;
        buf.seek((x + y * worldData.width) * 4);
        local landGroup = ((buf.readn('i') >> 16) & 0xFF);

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
        //printf("landmass %s", outPoint.tostring());
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

    function findRandomPointInWater(worldData, waterData){
        local randIndex = _random.randIndex(waterData.coords);
        return waterData.coords[randIndex];
    }

    function findRandomPositionInWater(worldData, waterGroupId){
        local waterGroup = worldData.waterData[waterGroupId];
        local point = findRandomPointInWater(worldData, waterGroup);

        local outPoint = Vec3(
            (point >> 16) & 0xFFFF, 0
            point & 0xFFFF);

        outPoint.z = -outPoint.z;

        return outPoint;
    }

};