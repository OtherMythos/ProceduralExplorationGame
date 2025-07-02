
::StressWorldGenBase <- {

    mMapGenerating_ = false

    mStartSeed_ = 100
    mMapNumCount_ = 0

    function setup(){
        _gameCore.registerMapGenClient("testClient", "res://../../src/MapGen/NativeClient/MapGenNativeClient.nut", {"basePath": "res://../../"});
        _gameCore.recollectMapGenSteps();
    }

    function update(){

        if(!mMapGenerating_){
            generate();
        }

        local stage = _gameCore.getMapGenStage();
        local result = _gameCore.checkClaimMapGen();
        if(result != null){
            mMapGenerating_ = false;
        }
    }

    function getSeedsForGenerate(){
        local targetSeed = mStartSeed_ + mMapNumCount_;
        local targetVariationSeed = mStartSeed_ + mMapNumCount_;
        local targetMoistureSeed = mStartSeed_ + mMapNumCount_;

        mMapNumCount_++;

        return {
            "seed": targetSeed,
            "variationSeed": targetVariationSeed,
            "moistureSeed": targetMoistureSeed,
        };
    }

    function generate(){
        local s = getSeedsForGenerate();

        local inputData = {
            "seed": s.seed,
            "variationSeed": s.variationSeed,
            "moistureSeed": s.moistureSeed,
            "width": 600,
            "height": 600,
            "numRivers": 24,
            "numRegions": 16,
            "seaLevel": 100,
        };

        if(mMapNumCount_ >= 10){
            _shutdownEngine();
        }

        _gameCore.beginMapGen(inputData);
        mMapGenerating_ = true;
    }

};