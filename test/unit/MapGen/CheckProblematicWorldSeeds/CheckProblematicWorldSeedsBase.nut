//Helper for checking world seeds which previously caused problems.

::CheckProblematicWorldSeedsBase <- {

    mMapGenerating_ = false
    mCurrentSeedIndex_ = 0
    mProblematicSeeds_ = []
    mTestsPassed_ = 0
    mTestsFailed_ = 0

    function setup(){
        _gameCore.registerMapGenClient("testClient", "res://../../../../src/MapGen/NativeClient/MapGenNativeClient.nut", {"basePath": "res://../../../../"});
        _gameCore.recollectMapGenSteps();

        //Load the problematic seeds JSON file
        local seedsData = _system.readJSONAsTable("res://problematicSeeds.json");
        if(seedsData != null){
            mProblematicSeeds_ = seedsData;
            print("Loaded " + mProblematicSeeds_.len() + " problematic seeds");
        }else{
            print("ERROR: Could not load problematicSeeds.json");
        }
    }

    function update(){
        if(mCurrentSeedIndex_ >= mProblematicSeeds_.len()){
            //All seeds tested
            local summary = [
                "TESTING COMPLETE",
                "Passed: " + mTestsPassed_,
                "Failed: " + mTestsFailed_,
            ];
            ::printTextBox(summary);
            _shutdownEngine();
            return;
        }

        if(!mMapGenerating_){
            generateWithCurrentSeed();
        }

        local result = _gameCore.checkClaimMapGen();
        if(result != null){
            mMapGenerating_ = false;

            //Check if generation succeeded
            local nativeData = result.data;

            local seedEntry = mProblematicSeeds_[mCurrentSeedIndex_];
            local values = [
                "SEED " + mCurrentSeedIndex_ + " " + (nativeData != null ? "PASSED" : "FAILED"),
                "Seed: " + seedEntry.seed,
                "Moisture: " + seedEntry.moistureSeed,
                "Variation: " + seedEntry.variationSeed,
                "Description: " + seedEntry.description,
            ];
            ::printTextBox(values);

            if(nativeData != null){
                mTestsPassed_++;

                _gameCore.destroyMapData(nativeData);
            }else{
                mTestsFailed_++;
            }

            mCurrentSeedIndex_++;
        }
    }

    function generateWithCurrentSeed(){
        if(mCurrentSeedIndex_ >= mProblematicSeeds_.len()){
            return;
        }

        local seedEntry = mProblematicSeeds_[mCurrentSeedIndex_];

        local inputData = {
            "seed": seedEntry.seed,
            "variationSeed": seedEntry.variationSeed,
            "moistureSeed": seedEntry.moistureSeed,
            "width": 600,
            "height": 600,
            "numRivers": 24,
            "numRegions": 16,
            "seaLevel": 100,
        };

        local values = [
            "GENERATING SEED",
            "Index: " + mCurrentSeedIndex_,
            "Seed: " + seedEntry.seed,
            "Moisture: " + seedEntry.moistureSeed,
            "Variation: " + seedEntry.variationSeed,
            "Description: " + seedEntry.description,
        ];
        ::printTextBox(values);

        _gameCore.beginMapGen(inputData);
        mMapGenerating_ = true;
    }

};
