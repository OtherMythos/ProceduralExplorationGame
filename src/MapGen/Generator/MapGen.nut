/**
 * Provides logic to construct a generated map for exploration.
 */
::MapGen <- class{

    constructor(){

    }

    function generate(data){
        _random.seedPatternGenerator(data.seed);

        local noiseBlob = _random.genPerlinNoise(data.width, data.height);

        local outData = {
            "voxelBuffer": noiseBlob
        };
        return outData;
    }

};