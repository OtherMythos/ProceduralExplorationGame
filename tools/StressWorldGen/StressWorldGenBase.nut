
::StressWorldGenBase <- {

    mMapGenerating_ = false

    mStartSeed_ = 100
    mMapNumCount_ = 0

    function setup(){
        _gameCore.registerMapGenClient("testClient", "res://../../src/MapGen/NativeClient/MapGenNativeClient.nut", {"basePath": "res://../../"});
        _gameCore.recollectMapGenSteps();

        mStartSeed_ = _random.randInt(1000);
    }

    function update(){

        if(!mMapGenerating_){
            generate();
        }

        local stage = _gameCore.getMapGenStage();
        local result = _gameCore.checkClaimMapGen();
        if(result != null){
            mMapGenerating_ = false;

            local nativeData = result.data;
            _gameCore.destroyMapData(nativeData);
        }
    }

    function getSeedsForGenerate(){
        local targetSeed = ::SeedHelper.pack(
            mStartSeed_ + mMapNumCount_,   //seedBase
            mStartSeed_ + mMapNumCount_,   //moisture
            mStartSeed_ + mMapNumCount_    //variation
        );

        mMapNumCount_++;

        local values = [
            "PROCEDURAL EXPLORATION SEEDS",
            "SEED   " + ::SeedHelper.toHex(targetSeed),
        ];
        ::printTextBox(values);

        return {
            "seed": 0x00002A2F4D5D15FC,
        };
    }

    function generate(){
        local s = getSeedsForGenerate();

        local inputData = {
            "seed": s.seed,
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