
enum MapVoxelTypes{
    SAND,
    DIRT,
    SNOW
};

/**
 * Provides logic to construct a generated map for exploration.
 */
::MapGen <- class{

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

    function designateLandmass(blob, data){
        blob.seek(0);
        for(local i = 0; i < data.width * data.height; i++){
            local pos = blob.tell();
            local val = blob.readn('i');
            if(val < 100){
                val = val / 2;
            }
            blob.seek(pos);
            blob.writen(val, 'i');
        }
    }

    function determineVoxelTypes(blob, data){
        blob.seek(0);
        for(local i = 0; i < data.width * data.height; i++){
            local pos = blob.tell();
            local val = blob.readn('i');

            local out = MapVoxelTypes.DIRT;
            if(val >= 0 && val <= 109) out = MapVoxelTypes.SAND;
            else if(val >= 110 && val <= 199) out = MapVoxelTypes.DIRT;
            else if(val >= 200 && val <= 255) out = MapVoxelTypes.SNOW;

            out = val | (out << 8);

            blob.seek(pos);
            blob.writen(out, 'i');
        }
    }

    function floodFillWaterEntry_(x, y, width, height, vals, blob, currentIdx){
        if(x < 0 || y < 0 || x >= width || y >= height) return;
        local idx = x+y*width;
        if(vals[idx] != 0xFF) return;

        local altitude = readAltitude_(blob, x, y, width);
        if(altitude >= 100){
            //This bit isn't water.
            return;
        }

        vals[idx] = currentIdx;
        floodFillWaterEntry_(x-1, y, width, height, vals, blob, currentIdx);
        floodFillWaterEntry_(x+1, y, width, height, vals, blob, currentIdx);
        floodFillWaterEntry_(x, y-1, width, height, vals, blob, currentIdx);
        floodFillWaterEntry_(x, y+1, width, height, vals, blob, currentIdx);
    }
    function floodFillWater(blob, data){
        local vals = array(data.width*data.height, 0xFF);
        local seedWaterVals = [];
        local currentIdx = 0;

        for(local y = 0; y < data.height; y++){
            for(local x = 0; x < data.width; x++){
                local altitude = readAltitude_(blob, x, y, data.width);
                if(altitude < 100){
                    //Designate this as water.
                    if(vals[x + y * data.width] == 0xFF){
                        floodFillWaterEntry_(x, y, data.width, data.height, vals, blob, currentIdx);
                        seedWaterVals.append([x, y]);
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
            current = current | ((vals[i] & 0xFF) << 16);

            blob.seek(pos);
            blob.writen(current, 'i');
        }

        assert(seedWaterVals.len() < 0xFF);
        return seedWaterVals;
    }

    function determineRiverOrigins(voxBlob, data){
        local origins = array(data.numRivers);
        //local riversBlob = blob(data.numRivers*4);
        for(local i = 0; i < data.numRivers; i++){
            local landPoint = findPointOnLand_(voxBlob, data, 150);
            origins[i] = landPoint;
            //riversBlob.writen(landPoint, 'i');
        }

        return origins;
    }

    function findMinNeighbourAltitude_(x, y, voxBlob, data, outCoords, foundData){
        local storage = [];
        if(!(wrapWorldPos_(x-1, y) in foundData)) storage.append(readAltitude_(voxBlob, x-1, y, data.width));
        if(!(wrapWorldPos_(x+1, y) in foundData)) storage.append(readAltitude_(voxBlob, x+1, y, data.width));
        if(!(wrapWorldPos_(x, y-1) in foundData)) storage.append(readAltitude_(voxBlob, x, y-1, data.width));
        if(!(wrapWorldPos_(x, y+1) in foundData)) storage.append(readAltitude_(voxBlob, x, y+1, data.width));

        local min = 0xFF;
        local minIdx = -1;
        foreach(c,i in storage){
            if(i < min){
                min = i;
                minIdx = c;
            }
        }
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
            default:{
                assert(false);
            }
        }

    }
    function calculateRivers(origins, voxBlob, data){
        local outData = [];
        local foundData = {};
        local outCoords = [0, 0];
        for(local river = 0; river < origins.len(); river++){
            local originX = (origins[river] >> 16) & 0xFF;
            local originY = origins[river] & 0xFF;
            outData.append(wrapWorldPos_(originX, originY));

            local currentX = originX;
            local currentY = originY;
            for(local i = 0; i < 50; i++){
                //Trace the river down to some other body of water.
                findMinNeighbourAltitude_(currentX, currentY, voxBlob, data, outCoords, foundData);
                currentX = outCoords[0];
                currentY = outCoords[1];
                local totalId = wrapWorldPos_(currentX, currentY);
                outData.append(totalId);
                foundData[totalId] <- river;
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

    function findPointOnLand_(voxBlob, data, minAltitude){
        local x = 0;
        local y = 0;
        //Just to avoid infinite loops.
        //TODO find a better way than this.
        for(local i = 0; i < 500; i++){
            x = _random.randInt(data.width);
            y = _random.randInt(data.height);
            local altitude = readAltitude_(voxBlob, x, y, data.width);
            if(altitude >= minAltitude) break;
        }
        local out = wrapWorldPos_(x, y);
        return out;
    }

    function wrapWorldPos_(x, y){
        return ((x & 0xFFFF) << 16) | (y & 0xFFFF);
    }

    function readVoxel_(blob, x, y, width){
    }
    function readAltitude_(blob, x, y, width){
        blob.seek((x + y * width) * 4);
        local val = blob.readn('i');
        return val & 0xFF;
    }

    function generate(data){
        _random.seedPatternGenerator(data.seed);

        local noiseBlob = _random.genPerlinNoise(data.width, data.height, 0.05, 4);
        assert(noiseBlob.len() == data.width*data.height*4);
        reduceNoise(noiseBlob, data);
        determineAltitude(noiseBlob, data);
        //designateLandmass(noiseBlob, data);
        determineVoxelTypes(noiseBlob, data);
        local waterSeeds = floodFillWater(noiseBlob, data);
        local riverOrigins = determineRiverOrigins(noiseBlob, data);
        local riverBuffer = calculateRivers(riverOrigins, noiseBlob, data);

        local outData = {
            "voxelBuffer": noiseBlob,
            "width": data.width,
            "height": data.height,
            "waterSeeds": waterSeeds,
            "riverBuffer": riverBuffer
        };
        return outData;
    }

};