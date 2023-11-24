
/**
 * Provides logic to construct a generated map for exploration.
 */
::MapGen <- class{

    mData_ = null;
    mTimer_ = null;

    mStages_ = [];
    mStagesNames_ = [];

    function reduceNoise_getHeightForPoint(input, x, y){
        local origin = 0.5;
        local centreOffset = (sqrt(pow(origin - x, 2) + pow(origin - y, 2)) + 0.1);
        local curvedOffset = 1 - pow(2, -10 * centreOffset*1.8);
        //curvedOffset *= 0.5;
        //curvedOffset = 1.0 - curvedOffset;
        // curvedOffset *= 1;
        // //float val = curvedOffset;
        local val = (1-centreOffset) * input;
        //local val = (1-curvedOffset) * input;
        //local mul = centreOffset*1.8;
        //local val = (1-(curvedOffset > 1.0 ? 1.0 : curvedOffset)) * input;
        //val *= 2;
        //val += 0.4;

        //val *= 1.2;

        //val += curvedOffset*0.8;

        return val > 1.0 ? 1.0 : val;
    }
    function reduceMoisture(moistureBlob, data){
        moistureBlob.seek(0);
        for(local i = 0; i < data.width * data.height; i++){
            local pos = moistureBlob.tell();
            local val = moistureBlob.readn('f');
            val = (val * 0xFF).tointeger();
            assert(val <= 0xFF);
            moistureBlob.seek(pos);
            moistureBlob.writen(val, 'i');
        }
    }
    function reduceNoise(blob, data){
        blob.seek(0);
        for(local y = 0; y < data.height; y++){
            local yVal = y.tofloat() / data.height;
            for(local x = 0; x < data.width; x++){
                local xVal = x.tofloat() / data.width;
                local pos = blob.tell();
                local val = blob.readn('f');
                local reduced = reduceNoise_getHeightForPoint(val, xVal, yVal);
                blob.seek(pos);
                blob.writen(reduced, 'f');
            }
        }
    }

    function determineAltitude(blob, data){
        blob.seek(0);
        for(local i = 0; i < data.width * data.height; i++){
            local pos = blob.tell();
            local val = blob.readn('f');
            val = (val * 0xFF).tointeger();
            assert(val <= 0xFF);
            blob.seek(pos);
            blob.writen(val, 'i');
        }
    }

    /*
    function determineRegions(secondaryBlob, data){
        secondaryBlob.seek(0);

        for(local y = 0; y < data.height; y++){
            for(local x = 0; x < data.width; x++){
                local pos = secondaryBlob.tell();
                local originalVal = secondaryBlob.readn('i');

                local targetRegion = (y / 40).tointeger();

                //Write the biome for now, later keep track of the biome group after the flood fill.
                local out = originalVal | (targetRegion << 8);

                secondaryBlob.seek(pos);
                secondaryBlob.writen(out, 'i');
            }
        }

        return (data.height / 40).tointeger();
    }
    */

    function determineRegionPoints_(secondaryBlob, landData, landWeighted, data){
        local outPoints = [];

        for(local i = 0; i < data.numRegions; i++){
            //Determine a single point and retry if it's too close to the others.
            local retLandmass = findRandomLandmassForSize(landData, landWeighted, 20);
            local coordData = landData[retLandmass].coords;
            local randIndex = _random.randIndex(coordData);
            local randPoint = coordData[randIndex];
            outPoints.append(randPoint);
        }

        return outPoints;
    }
    function determineRegionPoint_(secondaryBlob, landData, landWeighted, data, floodVals){
        //Attempt a few times, otherwise fail.
        for(local i = 0; i < 10; i++){
            //Determine a single point and retry if it's too close to the others.
            local retLandmass = findRandomLandmassForSize(landData, landWeighted, 20);
            local coordData = landData[retLandmass].coords;
            local randIndex = _random.randIndex(coordData);
            local randPoint = coordData[randIndex];

            local xTarget = (randPoint >> 16) & 0xFFFF;
            local yTarget = randPoint & 0xFFFF;
            //Don't place a region seed on an already existing region.
            if(floodVals[xTarget+yTarget*data.width] != 0xFF) continue;

            return randPoint;
        }

        return null;
    }
    function lazyFloodFill_(x, y, dequeue, floodVals, width, height){
        if(x < 0 || y < 0 || x >= width || y >= height) return;
        if(floodVals[x+y*width] != 0xFF) return;

        local wrappedPos = wrapWorldPos_(x, y);
        dequeue.append(wrappedPos);
    }
    function performLazyFloodFill_(startX, startY, width, height, regionId, blob, secondaryBlob, floodVals, floodData){
        local dequeue = [(startX << 16) | startY];
        //Flag to ensure the region draws something regardless of the random outcome.
        local first = true;

        while(dequeue.len() > 0){
            local target = dequeue[0];
            dequeue.remove(0);

            local targetX = (target >> 16) & 0xFFFF;
            local targetY = target & 0xFFFF;
            local idx = targetX+targetY*width;
            if(floodVals[idx] != 0xFF){
                if(first){
                    printf("The entire region with id %i was abandoned", regionId);
                    //assert(false);
                }
                continue;
            }

            floodData.coords.append(target);

            //The section is under the ocean so make it less likely to produce neighbour tiles.
            local altitude = readAltitude_(blob, targetX, targetY, width)
            local underwater = (altitude < mData_.seaLevel);

            floodVals[idx] = regionId;
            if(floodData.chance >= _random.randInt(underwater ? 300 : 100 || first)){
                lazyFloodFill_(targetX+1, targetY, dequeue, floodVals, width, height);
                lazyFloodFill_(targetX-1, targetY, dequeue, floodVals, width, height);
                lazyFloodFill_(targetX, targetY+1, dequeue, floodVals, width, height);
                lazyFloodFill_(targetX, targetY-1, dequeue, floodVals, width, height);
                first = false;
            }
            floodData.chance = floodData.chance * (underwater ? 0.9994 : floodData.decay);
        }
    }
    function determineRegions(voxelBlob, secondaryBlob, landmassData, landWeighted, data){
        local outData = [];
        secondaryBlob.seek(0);
        local vals = array(data.width*data.height, 0xFF);

        for(local c = 0; c < data.numRegions; c++){
            c++;
            local i = determineRegionPoint_(secondaryBlob, landmassData, landWeighted, data, vals);
            if(i == null) continue;
            local regionId = outData.len();
            local x = (i >> 16) & 0xFFFF;
            local y = i & 0xFFFF;
            local floodData = {
                //Add 1 so it doesn't try and populate for region 0, which is the default.
                "id": regionId,
                "total": 0,
                "seedX": x,
                "seedY": y,
                "startingVal": i,
                //"edges": [],
                "coords": [],
                "decay": 0.9995,
                "chance": 200.0,
            };
            performLazyFloodFill_(x, y, data.width, data.height, regionId, voxelBlob, secondaryBlob, vals, floodData);

            //Write the values to the blob.
            foreach(z in floodData.coords){
                local pos = (((z >> 16) & 0xFFFF) + (z & 0xFFFF) * data.width) * 4;
                secondaryBlob.seek(pos);
                local val = secondaryBlob.readn('i');
                secondaryBlob.seek(pos);
                val = val | (regionId << 8);
                //val = val | (100 << 8);
                secondaryBlob.writen(val, 'i');
            }
            outData.append(floodData);
        }

        return outData;
    }

    function processBiomeTypes(blob, secondaryBlob, data){
        blob.seek(0);
        secondaryBlob.seek(0);

        for(local y = 0; y < data.height; y++){
            for(local x = 0; x < data.width; x++){
                local pos = blob.tell();
                local originalVal = blob.readn('i');
                local altitude = originalVal & 0xFF;
                local flags = (originalVal >> 8) & 0xFF;
                local secondOriginal = secondaryBlob.readn('i');
                local moisture = secondOriginal & 0xFF;

                //The biome determines the type of the voxel as well as what gets placed, so instead determine the biome and pass off to that.
                local targetBiome = BiomeId.DEEP_OCEAN;
                if(altitude >= data.seaLevel){
                    targetBiome = BiomeId.GRASS_LAND;
                    if(altitude >= 120 && altitude <= 150){
                        if(moisture >= 150) targetBiome = BiomeId.GRASS_FOREST;
                    }
                }

                //Write the biome for now, later keep track of the biome group after the flood fill.
                local out = originalVal | (targetBiome << 8);

                blob.seek(pos);
                blob.writen(out, 'i');
            }
        }
    }
    function determineFinalBiomes(noiseBlob, biomeData){
        if(_random.randInt(1) == 0){
            local availableBiomes = [];
            foreach(c,i in biomeData){
                if(i.startingVal == BiomeId.GRASS_FOREST){
                    availableBiomes.append(c);
                }
            }
            //Decide which biome to alter.
            local index = _random.randIndex(availableBiomes);
            local data = availableBiomes[index];

            biomeData[data].startingVal = BiomeId.CHERRY_BLOSSOM_FOREST;
        }
    }
    function populateFinalBiomes(noiseBlob, secondaryBlob, blueNoise, biomeData){
        local placementItems = [];
        local VOX_FLAG_MASK = (0xFFFF00FF | MAP_VOXEL_MASK);

        local width = mData_.width;
        local height = mData_.height;
        foreach(i in biomeData){
            local targetBiome = i.startingVal;
            foreach(c,wrapped in i.coords){
                local x = (wrapped >> 16) & 0xFFFF;
                local y = wrapped & 0xFFFF;
                local pos = (x + y * width) * 4;
                noiseBlob.seek(pos);
                local val = noiseBlob.readn('i');
                local flags = (val >> 8) & ~MAP_VOXEL_MASK;
                secondaryBlob.seek(pos);
                local region = (secondaryBlob.readn('i') >> 8) & 0xFF;

                local biome = ::Biomes[targetBiome];
                local vox = biome.determineVoxFunction(val & 0xFF);
                biome.placeObjectsFunction(placementItems, blueNoise, x, y, width, height, val & 0xFF, region, flags);

                noiseBlob.seek(pos);
                noiseBlob.writen((val & VOX_FLAG_MASK) | (vox | flags) << 8, 'i');
            }
        }

        return placementItems;
    }

    function floodFill_(x, y, width, height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData){
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;
        local idx = x+y*width;
        if(vals[idx] != 0xFF) return 0;

        local readVal = readFunction(blob, x, y, width);
        if(!comparisonFunction(readVal)) return 1;

        if(x == 0 || y == 0 || x == width-1 || y == height-1){
            floodData.nextToWorldEdge = true;
        }

        vals[idx] = currentIdx;
        floodData.total++;
        local wrappedPos = wrapWorldPos_(x, y);
        floodData.coords.append(wrappedPos);
        local isEdge = 0;
        isEdge = isEdge | floodFill_(x-1, y, width, height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x+1, y, width, height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x, y-1, width, height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x, y+1, width, height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData);

        if(isEdge){
            floodData.edges.append(wrappedPos);
        }

        return 0;
    }

    checkingVal = null;
    function floodFill(comparisonFunction, readFunction, shiftVal, blob, data, writeToBlob=true){
        local vals = array(data.width*data.height, 0xFF);
        local outData = [];
        local currentIdx = 0;

        for(local y = 0; y < data.height; y++){
            for(local x = 0; x < data.width; x++){
                local altitude = readFunction(blob, x, y, data.width);
                checkingVal = altitude;
                if(comparisonFunction(altitude)){
                    //Designate this as water.
                    if(vals[x + y * data.width] == 0xFF){
                        local floodData = {
                            "id": currentIdx,
                            "total": 0,
                            "seedX": x,
                            "seedY": y,
                            "startingVal": checkingVal,
                            "nextToWorldEdge": false,
                            "edges": [],
                            "coords": []
                        };
                        floodFill_(x, y, data.width, data.height, readFunction, comparisonFunction, vals, blob, currentIdx, floodData);
                        outData.append(floodData);
                        currentIdx++;
                    }
                }
            }
        }

        if(writeToBlob){
            //Ensure sizes match up.
            assert(blob.len() == vals.len() * 4);
            //Commit the values to the blob.
            blob.seek(0);
            for(local i = 0; i < vals.len(); i++){
                local pos = blob.tell();
                local current = blob.readn('i');
                current = current | ((vals[i] & 0xFF) << shiftVal);

                blob.seek(pos);
                blob.writen(current, 'i');
            }
        }

        assert(outData.len() < 0xFF);
        return outData;
    }

    function floodFillWaterComparisonFunction_(altitude){
        return altitude < mData_.seaLevel;
    }
    function floodFillWater(blob, data){
        return floodFill(floodFillWaterComparisonFunction_, readAltitude_, 16, blob, data);
    }

    function floodFillBiomeComparisonFunction_(val){
        return (val & MAP_VOXEL_MASK) == checkingVal;
    }
    function floodFillBiomes(blob, data){
        return floodFill(floodFillBiomeComparisonFunction_, readWholeVoxel_, 8, blob, data, false);
    }

    function floodFillLandComparisonFunction_(altitude){
        return altitude >= mData_.seaLevel;
    }
    function floodFillLand(blob, data){
        return floodFill(floodFillLandComparisonFunction_, readAltitude_, 24, blob, data);
    }


    function floodFillLand_(x, y, width, height, comparisonFunction, blob, checked){
        if(x < 0 || y < 0 || x >= width || y >= height) return;
        local id = x | (y << 32);
        if(id in checked) return;

        local altitude = readAltitude_(blob, x, y, width);
        if(!comparisonFunction(altitude)) return;
        clearLandMass_(blob, x, y, width, mData_.seaLevel-1);
        checked[id] <- true;

        floodFillLand_(x-1, y, width, height, comparisonFunction, blob, checked);
        floodFillLand_(x+1, y, width, height, comparisonFunction, blob, checked);
        floodFillLand_(x, y-1, width, height, comparisonFunction, blob, checked);
        floodFillLand_(x, y+1, width, height, comparisonFunction, blob, checked);
    }
    function removeRedundantIslands(noiseBlob, data, landData){
        for(local i = 0; i < landData.len(); i++){
            local e = landData[i];
            local size = e.total;
            if(size <= 10){
                local checked = {};
                floodFillLand_(e.seedX, e.seedY, data.width, data.height, floodFillLandComparisonFunction_, noiseBlob, checked);
                landData[i] = null;
            }
        }

        //Clear all the nulls.
        local i = 0;
        while(i < landData.len()){
            if(landData[i] == null){
                landData.remove(i);
                continue;
            }
            i++;
        }
    }

    function determineRiverOrigins(voxBlob, landData, landWeighted, data){
        local origins = array(data.numRivers);
        for(local i = 0; i < data.numRivers; i++){
            local landId = findRandomLandmassForSize(landData, landWeighted, 20);
            local landPoint = findPointOnCoast_(landData, landId);
            origins[i] = {
                "origin": landPoint
            }
        }

        return origins;
    }

    function findMinNeighbourAltitude_(x, y, voxBlob, data, outCoords){
        local storage = [];
        storage.append(readAltitude_(voxBlob, x-1, y, data.width));
        storage.append(readAltitude_(voxBlob, x+1, y, data.width));
        storage.append(readAltitude_(voxBlob, x, y-1, data.width));
        storage.append(readAltitude_(voxBlob, x, y+1, data.width));

        storage.append(readAltitude_(voxBlob, x-1, y-1, data.width));
        storage.append(readAltitude_(voxBlob, x+1, y+1, data.width));
        storage.append(readAltitude_(voxBlob, x-1, y+1, data.width));
        storage.append(readAltitude_(voxBlob, x+1, y-1, data.width));

        local min = 0;
        local minIdx = -1;
        foreach(c,i in storage){
            if(i > min){
                min = i;
                minIdx = c;
            }
        }
        assert(storage.len() != 0);
        assert(min != 0xFF);
        //eww
        switch(minIdx){
            case 0:{
                outCoords[0] = x-1;
                outCoords[1] = y;
                break;
            }
            case 1:{
                outCoords[0] = x+1;
                outCoords[1] = y;
                break;
            }
            case 2:{
                outCoords[0] = x;
                outCoords[1] = y-1;
                break;
            }
            case 3:{
                outCoords[0] = x;
                outCoords[1] = y+1;
                break;
            }

            case 4:{
                outCoords[0] = x-1;
                outCoords[1] = y-1;
                break;
            }
            case 5:{
                outCoords[0] = x+1;
                outCoords[1] = y+1;
                break;
            }
            case 6:{
                outCoords[0] = x-1;
                outCoords[1] = y+1;
                break;
            }
            case 7:{
                outCoords[0] = x+1;
                outCoords[1] = y-1;
                break;
            }

            default:{
                print(minIdx);
                assert(false);
            }
        }

    }
    function calculateRivers(riverData, voxBlob, data){
        local outCoords = [0, 0];
        for(local river = 0; river < riverData.len(); river++){
            local outData = [];
            local rData = riverData[river];
            local originX = (rData.origin >> 16) & 0xFFFF;
            local originY = rData.origin & 0xFFFF;

            local currentX = originX;
            local currentY = originY;
            for(local i = 0; i < 100; i++){
                //Trace the river down to some other body of water.
                findMinNeighbourAltitude_(currentX, currentY, voxBlob, data, outCoords);
                currentX = outCoords[0];
                currentY = outCoords[1];
                local totalId = wrapWorldPos_(currentX, currentY);
                outData.append(totalId);
            }
            rData.points <- outData;
        }
    }

    function riverDataToBlob(riverData){
        local b = blob(3000*4);
        foreach(i in riverData){
            b.writen(i.origin, 'i');
            foreach(y in i.points){
                b.writen(y, 'i');
            }
            b.writen(0xFFFFFFFF, 'i');
        }
        b.writen(0xFFFFFFFF, 'i');

        return b;
    }

    function carveRivers(voxelBlob, riverBlob){
        riverBlob.seek(0);
        local first = true;
        local carvePos = {};
        while(true){
            local wrappedPos = riverBlob.readn('i');
            if(wrappedPos < 0){
                if(first == true){
                    break;
                }
                first = true;
                continue;
            }
            first = false;

            //Batch up the positions to carve so they don't get applied twice.
            carvePos.rawset(wrappedPos, null);
            carvePos.rawset(((((wrappedPos >> 16) & 0xFFFF)-1)<<16) | (wrappedPos&0xFFFF), null);
            carvePos.rawset(((((wrappedPos >> 16) & 0xFFFF)+1)<<16) | (wrappedPos&0xFFFF), null);
            carvePos.rawset(wrappedPos&0xFFFF0000 | (wrappedPos&0xFFFF)-1, null);
            carvePos.rawset(wrappedPos&0xFFFF0000 | (wrappedPos&0xFFFF)+1, null);
        }

        foreach(c,i in carvePos){
            local xPos = (c >> 16) & 0xFFFF;
            local yPos = c & 0xFFFF;
            //alterLandmass_(voxelBlob, xPos, yPos, mData_.width, -4);
            markVoxelAsRiver_(voxelBlob, xPos, yPos, mData_.width);
        }
    }

    function outlineEdges_(data, blob){
        foreach(d in data){
            local edges = d.edges;
            for(local i = 0; i < edges.len(); i++){
                local x = (edges[i] >> 16) & 0xFFFF;
                local y = (edges[i]) & 0xFFFF;
                local pos = (x + y * mData_.width) * 4;
                blob.seek(pos);
                local val = blob.readn('i');
                val = val | 1 << 15;
                blob.seek(pos);
                blob.writen(val, 'i');
            }
        }
    }
    function outlineEdges(noiseBlob, waterData, landData){
        outlineEdges_(landData, noiseBlob);
        outlineEdges_(waterData, noiseBlob);
    }

    function findPointOnCoast_(landData, landId){
        local edges = landData[landId].edges;
        local randIndex = _random.randIndex(edges);
        return edges[randIndex];
    }

    function sortLandmassesBySize(landData){
        landData.sort(function(a,b){
            if(a.total<b.total) return 1;
            else if(a.total>b.total) return -1;
            return 0;
        });
    }

    function determinePlayerStart(landData, landWeighted){
        //Just go with the biggest for now.
        local data = landData[0];
        return findRandomPointInLandmass(data);
    }

    function findRandomPointInLandmass(landData){
        local randIndex = _random.randIndex(landData.coords);
        return landData.coords[randIndex];
    }
    function checkPointValidForFlags(blob, packedOrigin, flags){
        local f = readVoxFlags_(blob, (packedOrigin >> 16) & 0xFFFF, packedOrigin & 0xFFFF, mData_.width);
        return (f & flags) == 0;
    }

    /**
     * Generate a list with 100 entries, where each entry is a value in the land data list.
     * Values are weighted based on their total size in the total landmasses.
     */
    function generateLandWeightedAverage(landData){
        local totalLand = 0;
        foreach(i in landData){
            totalLand += i.total;
        }
        local weighted = array(100, 0);
        local count = 0;
        //Head through the list backwards.
        //Smaller landmasses should be at the back, ensure that each piece of land gets one entry in the list.
        //In this case the smaller landmasses will steal from the largest landmass.
        local startIdx = landData.len() > 100 ? 100 : landData.len()-1;
        for(local i = startIdx; i >= 0; i--){
            local weightFloat = (landData[i].total.tofloat() / totalLand) * 100;
            local weight = weightFloat >= 1.0 ? weightFloat.tointeger() : 1;
            for(local y = 0; y < weight; y++){
                weighted[count] = i;
                count++;
                //Drop out if the array is populated.
                if(count >= 100){
                    //Assuming we stop on the largest landmass.
                    assert(i == 0);
                    return weighted;
                }
            }
        }

        return weighted;
    }

    function findRandomLandmassForSize(landData, landWeighted, size){
        //To avoid infinite loops.
        for(local i = 0; i < 100; i++){
            local randIndex = _random.randIndex(landWeighted);
            local idx = landWeighted[randIndex];
            if(landData[idx].total >= size){
                return idx;
            }
        }
        return 0;
    }
    function determinePlaces_determineLandmassForPlace(landData, landWeighted, place){
        local placeType = place.getType();
        if(placeType == PlaceType.CITY || placeType == PlaceType.GATEWAY){
            //This being the largest landmass, place the city there.
            return 0;
        }
        local retLandmass = findRandomLandmassForSize(landData, landWeighted, place.getMinLandmass());

        return retLandmass;
    }
    function determinePlaces_place(noiseBlob, secondaryBlob, landData, landWeighted, place, placeId){
        local landmassId = determinePlaces_determineLandmassForPlace(landData, landWeighted, place);
        local landmass = landData[landmassId];

        local point = null;
        //Avoid infinite loops incase of not finding a suitable place.
        for(local i = 0; i < 100; i++){
            local intended = findRandomPointInLandmass(landmass);
            if(checkPointValidForFlags(noiseBlob, intended, MapVoxelTypes.RIVER)){
                //In this case stop the check.
                point = intended;
                break;
            }
        }
        if(point == null) return null;

        //Determine the region.
        local originX = (point >> 16) & 0xFFFF;
        local originY = point & 0xFFFF;
        secondaryBlob.seek((originX + originY * mData_.width) * 4);
        local region = ((secondaryBlob.readn('i') >> 8) & 0xFF);

        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "originWrapped": point,
            "placeId": placeId,
            "region": region
        };
        return placeData;
    }
    function determinePlaces(noiseBlob, secondaryBlob, landData, landWeighted, data){
        local placeData = [];

        foreach(c,freq in data.placeFrequency){
            for(local i = 0; i < freq; i++){
                //To get around the NONE.
                local totalPlaces = ::PlacesByType[c];
                if(totalPlaces.len() == 0) break;
                local targetPlace = totalPlaces[_random.randIndex(totalPlaces)];
                local place = ::Places[targetPlace];
                local addedPlace = determinePlaces_place(noiseBlob, secondaryBlob, landData, landWeighted, place, targetPlace);
                if(addedPlace == null) continue;
                placeData.append(addedPlace);
            }
        }

        return placeData;
    }

    function wrapWorldPos_(x, y){
        return ((x & 0xFFFF) << 16) | (y & 0xFFFF);
    }

    function readAltitude_(blob, x, y, width){
        blob.seek((x + y * width) * 4);
        local val = blob.readn('i');
        return val & 0xFF;
    }
    function readVoxFlags_(blob, x, y, width){
        blob.seek((x + y * width) * 4);
        local val = (blob.readn('i') >> 8) & ~MAP_VOXEL_MASK;
        return val;
    }
    function readWholeVoxel_(blob, x, y, width){
        blob.seek((x + y * width) * 4);
        local val = (blob.readn('i') >> 8);
        return val & 0xFF;
    }

    function markVoxelAsRiver_(blob, x, y, width){
        local pos = (x + y * width) * 4;
        blob.seek(pos);
        local original = blob.readn('i');
        blob.seek(pos);
        blob.writen(original | (MapVoxelTypes.RIVER << 8), 'i');
    }
    /**
     * Reduce the current landmass altitude by the requested amount.
     */
    function alterLandmass_(blob, x, y, width, dipVal){
        local pos = (x + y * width) * 4;
        blob.seek(pos);
        local original = blob.readn('i');
        local altitude = original & 0xFF;
        local newVal = original & 0xFFFFFF00;
        local val = altitude + dipVal;
        if(val < 0) val = 0;
        if(val > 0xFF) val = 0xFF;
        assert(val >= 0 && val <= 0xFF);
        newVal = newVal | val;
        blob.seek(pos);
        blob.writen(newVal, 'i');
    }
    function clearLandMass_(blob, x, y, width, val){
        local pos = (x + y * width) * 4;
        blob.seek(pos);
        local original = blob.readn('i');
        local newVal = original & 0x0000FF00;
        newVal = newVal | val;
        blob.seek(pos);
        blob.writen(newVal, 'i');
    }

    function printFloodFillData_(title, data){
        print("============" + title + "============");
        foreach(c,i in data){
            print("== Entry: " + c + " ==");
            print("id: " + i.id);
            print("total: " + i.total);
            print("seedX: " + i.seedX);
            print("seedY: " + i.seedY);
            print("nextToWorldEdge: " + i.nextToWorldEdge);
            print("numEdges: " + i.edges.len());
        }
        print("==================================");
    }

    function printPlaceData(data){
        print("============Place============");
        foreach(c,i in data){
            print("== Entry: " + c + " ==");
            print("originX " + i.originX);
            print("originY " + i.originY);
            print("placeId " + i.placeId);
        }
        print("=============================");
    }

    constructor(){
        mTimer_ = Timer();
    }

    function generate(data){
        mTimer_.start();

        mData_ = data;
        _random.seedPatternGenerator(data.seed);
        _random.seed(data.variation);

        local workspace = {
            "data": data
        };
        foreach(c,i in mStages_){
            i(workspace);
            local currentPercent = c.tofloat() / mStages_.len().tofloat();
            ::suspend({
                "name": mStagesNames_[c],
                "percentage": currentPercent,
            });
        }

        mTimer_.stop();

        //printFloodFillData_("water", waterData);
        //printFloodFillData_("land", landData);

        printPlaceData(workspace.placeData);

        local outData = {
            "voxelBuffer": workspace.noiseBlob,
            "secondaryVoxBuffer": workspace.secondaryBiomeBlob,
            "blueNoiseBuffer": workspace.blueNoise,
            "width": data.width,
            "height": data.height,
            "waterData": workspace.waterData,
            "landData": workspace.landData,
            "biomeData": workspace.biomeData,
            "riverBuffer": workspace.riverBuffer,
            "seaLevel": data.seaLevel,
            "placeData": workspace.placeData,
            "placedItems": workspace.placedItems,
            "regionData": workspace.regionData,
            "playerStart": workspace.playerStart,
            "stats": {
                "totalSeconds": mTimer_.getSeconds()
            }
        };

        //Reset the seed
        //TODO with threading this will need to be reset back and forth to maintain consistency
        _random.seed(_system.time());
        return outData;
    }

};

function registerGenerationStage(name, func){
    ::MapGen.mStages_.append(func);
    ::MapGen.mStagesNames_.append(name);
}

registerGenerationStage("Generate noise", function(workspace){
    local data = workspace.data;
    local noiseBlob = _random.genPerlinNoise(data.width, data.height, 0.02, 4);
    assert(noiseBlob.len() == data.width*data.height*4);

    _random.seedPatternGenerator(data.moistureSeed);
    local secondaryBiomeBlob = _random.genPerlinNoise(data.width, data.height, 0.05, 4);
    assert(secondaryBiomeBlob.len() == data.width*data.height*4);

    local blueNoise = _random.genPerlinNoise(data.width, data.height, 0.5, 1);
    assert(blueNoise.len() == data.width*data.height*4);

    workspace.noiseBlob <- noiseBlob;
    workspace.secondaryBiomeBlob <- secondaryBiomeBlob;
    workspace.blueNoise <- blueNoise;
});
registerGenerationStage("Reduce noise", function(workspace){
    reduceMoisture(workspace.secondaryBiomeBlob, workspace.data);
    reduceNoise(workspace.noiseBlob, workspace.data);
});
registerGenerationStage("Altitude", function(workspace){
    determineAltitude(workspace.noiseBlob, workspace.data);
});
registerGenerationStage("perform flood fill", function(workspace){
    workspace.waterData <- floodFillWater(workspace.noiseBlob, workspace.data);
    workspace.landData <- floodFillLand(workspace.noiseBlob, workspace.data);
});
registerGenerationStage("Remove redundant islands", function(workspace){
    removeRedundantIslands(workspace.noiseBlob, workspace.data, workspace.landData);
});
registerGenerationStage("Weight and sort landmasses", function(workspace){
    sortLandmassesBySize(workspace.landData);
    workspace.landWeighted <- generateLandWeightedAverage(workspace.landData);
});
registerGenerationStage("Determine edges", function(workspace){
    outlineEdges(workspace.noiseBlob, workspace.waterData, workspace.landData);
});
registerGenerationStage("Determine rivers", function(workspace){
    local riverData = determineRiverOrigins(workspace.noiseBlob, workspace.landData, workspace.landWeighted, workspace.data);
    calculateRivers(riverData, workspace.noiseBlob, workspace.data);
    local riverBuffer = riverDataToBlob(riverData);
    carveRivers(workspace.noiseBlob, riverBuffer);

    workspace.riverData <- riverData;
    workspace.riverBuffer <- riverBuffer;
});
registerGenerationStage("Determine regions", function(workspace){
    workspace.regionData <- determineRegions(workspace.noiseBlob, workspace.secondaryBiomeBlob, workspace.landData, workspace.landWeighted, workspace.data);
});
registerGenerationStage("Determine biomes", function(workspace){
    processBiomeTypes(workspace.noiseBlob, workspace.secondaryBiomeBlob, workspace.data);
    local biomeData = floodFillBiomes(workspace.noiseBlob, workspace.data);
    determineFinalBiomes(workspace.noiseBlob, biomeData);

    workspace.biomeData <- biomeData;
});
registerGenerationStage("Place biome items", function(workspace){
    workspace.placedItems <- populateFinalBiomes(workspace.noiseBlob, workspace.secondaryBiomeBlob, workspace.blueNoise, workspace.biomeData);
});
registerGenerationStage("Determine places", function(workspace){
    workspace.placeData <- determinePlaces(workspace.noiseBlob, workspace.secondaryBiomeBlob, workspace.landData, workspace.landWeighted, workspace.data);
});
registerGenerationStage("Determine player start", function(workspace){
    workspace.playerStart <- determinePlayerStart(workspace.landData, workspace.landWeighted);
});