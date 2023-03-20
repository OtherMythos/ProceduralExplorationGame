
enum MapVoxelTypes{
    SAND,
    DIRT,
    SNOW
};

/**
 * Provides logic to construct a generated map for exploration.
 */
::MapGen <- class{

    mData_ = null;

    constructor(){

    }

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

    function determineVoxelTypes(blob, data){
        blob.seek(0);

        local biomeSand = data.seaLevel + data.altitudeBiomes[0];
        local biomeGround = data.seaLevel + data.altitudeBiomes[1];

        for(local i = 0; i < data.width * data.height; i++){
            local pos = blob.tell();
            local originalVal = blob.readn('i');
            local val = originalVal & 0xFF;

            local out = MapVoxelTypes.DIRT;
            if(val >= 0 && val < biomeSand) out = MapVoxelTypes.SAND;
            else if(val >= biomeSand && val < biomeGround) out = MapVoxelTypes.DIRT;
            else if(val >= biomeGround && val <= 255) out = MapVoxelTypes.SNOW;
            else{
                assert(false);
            }

            out = originalVal | (out << 8);

            blob.seek(pos);
            blob.writen(out, 'i');
        }
    }


    function floodFill_(x, y, width, height, comparisonFunction, vals, blob, currentIdx, floodData){
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;
        local idx = x+y*width;
        if(vals[idx] != 0xFF) return 0;

        local altitude = readAltitude_(blob, x, y, width);
        if(!comparisonFunction(altitude)) return 1;

        if(x == 0 || y == 0 || x == width-1 || y == height-1){
            floodData.nextToWorldEdge = true;
        }

        vals[idx] = currentIdx;
        floodData.total++;
        local isEdge = 0;
        isEdge = isEdge | floodFill_(x-1, y, width, height, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x+1, y, width, height, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x, y-1, width, height, comparisonFunction, vals, blob, currentIdx, floodData);
        isEdge = isEdge | floodFill_(x, y+1, width, height, comparisonFunction, vals, blob, currentIdx, floodData);

        if(isEdge){
            floodData.edges.append(wrapWorldPos_(x, y));
        }

        return 0;
    }

    function floodFill(comparisonFunction, shiftVal, blob, data){
        local vals = array(data.width*data.height, 0xFF);
        local outData = [];
        local currentIdx = 0;

        for(local y = 0; y < data.height; y++){
            for(local x = 0; x < data.width; x++){
                local altitude = readAltitude_(blob, x, y, data.width);
                if(comparisonFunction(altitude)){
                    //Designate this as water.
                    if(vals[x + y * data.width] == 0xFF){
                        local floodData = {
                            "id": currentIdx,
                            "total": 0,
                            "seedX": x,
                            "seedY": y,
                            "nextToWorldEdge": false,
                            "edges": []
                        };
                        floodFill_(x, y, data.width, data.height, comparisonFunction, vals, blob, currentIdx, floodData);
                        outData.append(floodData);
                        currentIdx++;
                    }
                }
            }
        }

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

        assert(outData.len() < 0xFF);
        return outData;
    }

    function floodFillWaterComparisonFunction_(altitude){
        return altitude < mData_.seaLevel;
    }
    function floodFillWater(blob, data){
        return floodFill(floodFillWaterComparisonFunction_, 16, blob, data);
    }

    function floodFillLandComparisonFunction_(altitude){
        return altitude >= mData_.seaLevel;
    }
    function floodFillLand(blob, data){
        return floodFill(floodFillLandComparisonFunction_, 24, blob, data);
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

    function determineRiverOrigins(voxBlob, landData, data){
        local origins = array(data.numRivers);
        for(local i = 0; i < data.numRivers; i++){
            local landPoint = findPointOnCoast_(landData);
            origins[i] = landPoint;
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
    function calculateRivers(origins, voxBlob, data){
        local outData = [];
        local outCoords = [0, 0];
        for(local river = 0; river < origins.len(); river++){
            local originX = (origins[river] >> 16) & 0xFFFF;
            local originY = origins[river] & 0xFFFF;
            outData.append(wrapWorldPos_(originX, originY));

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
            outData.append(0xFFFFFFFF);
        }
        outData.append(0xFFFFFFFF);

        //Copy values to a blob.
        local riverData = blob(outData.len() * 4);
        foreach(i in outData){
            riverData.writen(i, 'i');
        }

        return riverData;
    }

    function carveRivers(voxelBlob, riverBlob){
        riverBlob.seek(0);
        local first = true;
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
            local xPos = (wrappedPos >> 16) & 0xFFFF;
            local yPos = wrappedPos & 0xFFFF;

            clearLandMass_(voxelBlob, xPos, yPos, mData_.width, mData_.seaLevel-1);
            //Add a bit of a circle around it.
            clearLandMass_(voxelBlob, xPos-1, yPos, mData_.width, mData_.seaLevel-1);
            clearLandMass_(voxelBlob, xPos+1, yPos, mData_.width, mData_.seaLevel-1);
            clearLandMass_(voxelBlob, xPos, yPos-1, mData_.width, mData_.seaLevel-1);
            clearLandMass_(voxelBlob, xPos, yPos+1, mData_.width, mData_.seaLevel-1);
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

    function findPointOnCoast_(landData, land=0){
        local edges = landData[land].edges;
        local randIndex = _random.randIndex(edges);
        return edges[randIndex];
    }

    function findPointOnLand_(voxBlob, data, minAltitude){
        local x = 0;
        local y = 0;
        //Just to avoid infinite loops.
        for(local i = 0; i < 100; i++){
            x = _random.randInt(data.width);
            y = _random.randInt(data.height);
            local altitude = readAltitude_(voxBlob, x, y, data.width);
            if(altitude >= minAltitude) break;
        }
        local out = wrapWorldPos_(x, y);
        return out;
    }


    function sortLandmassesBySize(landData){
        landData.sort(function(a,b){
            if(a.total<b.total) return 1;
            else if(a.total>b.total) return -1;
            return 0;
        });
    }

    function findRandomPointInLandmass(landData){
        local randIndex = _random.randIndex(landData.edges);
        return landData.edges[randIndex];
    }


    function determinePlaces_determineLandmassForPlace(landData, place){
        local placeType = place.getType();
        if(placeType == PlaceType.CITY){
            //This being the largest landmass, place the city there.
            return 0;
        }

        return 0;
    }
    function determinePlaces_place(noiseBlob, landData, place, placeId){
        local landmassId = determinePlaces_determineLandmassForPlace(landData, place);
        local landmass = landData[landmassId];
        local point = findRandomPointInLandmass(landmass);

        print("Added " + point);
        local placeData = {
            "originX": (point >> 16) & 0xFFFF,
            "originY": point & 0xFFFF,
            "placeId": placeId
        };
        return placeData;
    }
    function determinePlaces(noiseBlob, landData, data){
        local placeData = [];

        foreach(c,freq in data.placeFrequency){
            for(local i = 0; i < freq; i++){
                //To get around the NONE.
                local totalPlaces = ::PlacesByType[c];
                if(totalPlaces.len() == 0) break;
                local targetPlace = totalPlaces[_random.randIndex(totalPlaces)];
                local place = ::Places[targetPlace];
                local addedPlace = determinePlaces_place(noiseBlob, landData, place, targetPlace);
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

    function generate(data){
        mData_ = data;
        _random.seedPatternGenerator(data.seed);
        _random.seed(data.variation);

        local noiseBlob = _random.genPerlinNoise(data.width, data.height, 0.05, 4);
        assert(noiseBlob.len() == data.width*data.height*4);
        reduceNoise(noiseBlob, data);
        determineAltitude(noiseBlob, data);
        local waterData = floodFillWater(noiseBlob, data);
        local landData = floodFillLand(noiseBlob, data);
        removeRedundantIslands(noiseBlob, data, landData);
        sortLandmassesBySize(landData);
        determineVoxelTypes(noiseBlob, data);
        outlineEdges(noiseBlob, waterData, landData)
        local riverOrigins = determineRiverOrigins(noiseBlob, landData, data);
        local riverBuffer = calculateRivers(riverOrigins, noiseBlob, data);
        carveRivers(noiseBlob, riverBuffer);
        local placeData = determinePlaces(noiseBlob, landData, data);

        //printFloodFillData_("water", waterData);
        //printFloodFillData_("land", landData);

        printPlaceData(placeData);

        local outData = {
            "voxelBuffer": noiseBlob,
            "width": data.width,
            "height": data.height,
            "waterData": waterData,
            "landData": landData,
            "riverBuffer": riverBuffer,
            "seaLevel": data.seaLevel,
            "placeData": placeData
        };

        //Reset the seed
        _random.seed(_system.time());
        return outData;
    }

};