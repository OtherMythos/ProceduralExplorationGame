
::ProceduralExplorationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    constructor(){

    }

    #Override
    function processPreparation(){
        assert(mCurrentPercent_ < 1.0);

        resetSessionGenMap();

        return mCurrentPercent_ >= 1.0;
    }

    function resetSessionGenMap(){
        mCurrentPercent_ = 0.0;

        local gen = ::MapGen();
        local data = {
            "seed": 77749,
            "moistureSeed": 84715,
            "variation": 0,
            "width": 400,
            "height": 400,
            "numRivers": 24,
            "seaLevel": 100,
            "numRegions": 16,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        local outData = gen.generate(data);
        print("World generation completed in " + outData.stats.totalSeconds);

        //resetSession(outData);
        mOutData_ = outData;

        mCurrentPercent_ = 1.0;
    }

    function getOutputData(){
        return mOutData_;
    }

}