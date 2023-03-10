/**
 * Provides logic to construct a generated map for exploration.
 */
::MapGen <- class{

    constructor(){

    }

    function reduceNoise_getHeightForPoint(input, x, y){
        local origin = 0.5;
        local centreOffset = (sqrt(pow(origin - x, 2) + pow(origin - y, 2)) + 0.1);
        local curvedOffset = centreOffset == 1 ? 1 : 1 - pow(2, -10 * centreOffset);
        curvedOffset = 1.0 - curvedOffset;
        // curvedOffset *= 1;
        // //float val = curvedOffset;
        local val = (1-centreOffset) * input;   
        val *= 1.5;

        val += curvedOffset*0.8;

        return val;
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

    function designateLandmass(blob, data){
        blob.seek(0);
        for(local i = 0; i < data.width * data.height; i++){
            local pos = blob.tell();
            local val = blob.readn('f');
            val = val <= 0.5 ? 0.0 : 1.0;
            blob.seek(pos);
            blob.writen(val, 'f');
        }
    }

    function generate(data){
        _random.seedPatternGenerator(data.seed);

        local noiseBlob = _random.genPerlinNoise(data.width, data.height);
        reduceNoise(noiseBlob, data);
        designateLandmass(noiseBlob, data);

        local outData = {
            "voxelBuffer": noiseBlob
        };
        return outData;
    }

};