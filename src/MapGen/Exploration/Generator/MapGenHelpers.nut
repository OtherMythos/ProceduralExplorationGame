::MapGenHelpers <- {

    //TODO reduce some of the duplication in the actual map generator.
    function getLandmassForPos(worldData, pos){
        return ::currentNativeMapData.getLandmassForPos(pos);
/*
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        if(x < 0 || y < 0 || x >= worldData.width || y >= worldData.height) return null;

        local buf = worldData.voxelBuffer;
        buf.seek((x + y * worldData.width) * 4);
        local landGroup = ((buf.readn('i') >> 24) & 0xFF);

        return landGroup == 255 ? null : landGroup;
*/
    }

    function getIsWaterForPosition(worldData, pos){
        return ::currentNativeMapData.getIsWaterForPos(pos);
        /*
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
        */
    }
    function getRegionForData(worldData, pos){
        return ::currentNativeMapData.getRegionForPos(pos);
        /*
        local x = pos.x.tointeger();
        local y = -pos.z.tointeger();

        if(x < 0 || y < 0 || x >= worldData.width || y >= worldData.height) return -1;

        local voxBuff = worldData.secondaryVoxBuffer;
        voxBuff.seek((x + y * worldData.width) * 4);
        local val = ((voxBuff.readn('i') >> 8) & 0xFF);
        return val;
        */
    }

    function getRegionForPoint(worldData, point){
        //TODO OPTIMISATION would be better to shift all this to C++.
        local xPos = (point >> 16) & 0xFFFF;
        local yPos = point & 0xFFFF;
        return worldData.getRegionForPos(Vec3(xPos, 0, -yPos));
    }

    function getTraverseTerrainForPosition(worldData, pos){
        return getIsWaterForPosition(worldData, pos) ? EnemyTraversableTerrain.WATER : EnemyTraversableTerrain.LAND;
    }

    function findRandomPointInLandmass(landData){
        local randIndex = _random.randIndex(landData.coords);
        return landData.coords[randIndex];
    }

    function findRandomPointInRegion(regionData){
        local randIndex = _random.randIndex(regionData.coords);
        return regionData.coords[randIndex];
    }

    function findRandomPointOnLand(worldData, start, radius, minRadius=0){
        local offset = Vec3(0.5, 0, 0.5);
        for(local i = 0; i < 100; i++){
            local targetDir = (_random.randVec3() - offset);
            local targetPos = start + (targetDir * minRadius) + (targetDir * (radius - minRadius));
            targetPos.y = 0;
            local landmassId = ::MapGenHelpers.getLandmassForPos(worldData, targetPos);
            if(landmassId == 0xFF) continue;
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

    function getBiomeForRegionType(regionType){
        switch(regionType){
            case RegionType.GRASSLAND: return ::Biomes[BiomeId.GRASS_LAND];
            case RegionType.CHERRY_BLOSSOM_FOREST: return ::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST];
            case RegionType.EXP_FIELDS: return ::Biomes[BiomeId.EXP_FIELD];
            case RegionType.DESERT: return ::Biomes[BiomeId.DESERT];
            default:{
                return ::Biomes[BiomeId.GRASS_LAND];
            }
        }
    }

};