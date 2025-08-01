
::ProceduralExplorationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;
    mOutNativeData_ = null;

    //mThread_ = null;
    mStarted_ = false;
    mCurrentStage_ = 0;

    mInputData_ = null;

    constructor(){

    }

    #Override
    function processPreparation(){
        assert(mCurrentPercent_ < 1.0);

        if(!mStarted_){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": true, "ended": false});
            mCurrentStage_ = 0;

            local seed = _random.randInt(1000);
            local moistureSeed = _random.randInt(1000);
            local variationSeed = _random.randInt(1000);

            local values = [
                "PROCEDURAL EXPLORATION SEEDS",
                "SEED   " + seed,
                "MOISTURE   " + moistureSeed,
                "VARIATION   " + variationSeed,
            ];
            ::printTextBox(values);

            local smallWorld = ::Base.isProfileActive(GameProfile.FORCE_SMALL_WORLD);
            mInputData_ = {
                "seed": seed,
                "moistureSeed": moistureSeed,
                "variationSeed": variationSeed,
                "width": smallWorld ? 200 : 600,
                "height": smallWorld ? 200 : 600,
                "numRivers": 24,
                "seaLevel": 100,
                "numRegions": 14,
                "boxWidth": 20,
                "boxHeight": 20,
                "placeFrequency": [0, 1, 1, 4, 4, 30]
            };
            _gameCore.beginMapGen(mInputData_);
            mStarted_ = true;
        }

        local mapClaim = _gameCore.checkClaimMapGen();
        if(mapClaim != null){
            mOutNativeData_ = mapClaim.data;
            //TODO work towards being able to get rid of this.
            mOutData_ = mOutNativeData_.explorationMapDataToTable();
            //mOutData_.rawset("placeData", scriptMapGen.determinePlaces());
            //print(_prettyPrint(mapClaim.testClient));
            mOutData_.rawset("placeData", mapClaim.testClient.placeData);
            mCurrentPercent_ = 1.0;
            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, {
                "percentage": mCurrentPercent_,
                "name": "done"
            });
        }else{
            local mapGenStage = _gameCore.getMapGenStage();
            if(mCurrentStage_ != mapGenStage){
                while(mCurrentStage_ != mapGenStage){
                    mCurrentPercent_ = mCurrentStage_.tofloat() / _gameCore.getTotalMapGenStages().tofloat();
                    local stageName = _gameCore.getNameForMapGenStage(mCurrentStage_);
                    print("PROCEDURAL WORLD GENERATION: " + (mCurrentPercent_ * 100).tointeger() + "% stage: " + stageName);

                    _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, {
                        "percentage": mCurrentPercent_,
                        "name": stageName
                    });
                    mCurrentStage_++;
                }
            }
        }

        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }
        return mCurrentPercent_ >= 1.0;


        /*
        assert(mCurrentPercent_ < 1.0);

        local susparam = null;
        if(mThread_ == null){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": true, "ended": false});
            mThread_ = ::newthread(resetSessionGenMap);
            susparam = mThread_.call();
        }

        susparam = mThread_.wakeup();

        if(mThread_.getstatus()=="idle"){
            mOutData_ = susparam;
            mCurrentPercent_ = 1.0;
            mThread_ = null;
            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, {
                "percentage": mCurrentPercent_,
                "name": "done"
            });
        }else{
            mCurrentPercent_ = susparam.percentage;
            print("PROCEDURAL WORLD GENERATION: " + (mCurrentPercent_ * 100).tointeger() + "% stage: " + susparam.name);

            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, susparam);
        }

        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }
        return mCurrentPercent_ >= 1.0;
        */
    }

    /*
    function resetSessionGenMap(){
        local smallWorld = ::Base.isProfileActive(GameProfile.FORCE_SMALL_WORLD);

        local gen = ::MapGen();
        local data = {
            "seed": _random.randInt(1000),
            "moistureSeed": _random.randInt(1000),
            "variation": _random.randInt(1000),
            "width": smallWorld ? 200 : 600,
            "height": smallWorld ? 200 : 600,
            "numRivers": 24,
            "seaLevel": 100,
            "numRegions": 14,
            "altitudeBiomes": [10, 100],
            "placeFrequency": [0, 1, 1, 4, 4, 30]
        };
        print("PROCEDURAL WORLD PREPARER: seed: " + data.seed.tostring())
        print("PROCEDURAL WORLD PREPARER: moisture seed: " + data.moistureSeed.tostring())
        print("PROCEDURAL WORLD PREPARER: variation: " + data.variation.tostring())
        local outData = gen.generate(data);
        print("World generation completed in " + outData.stats.totalSeconds);

        return outData;
    }
    */

    function getOutputData(){
        return mOutData_;
    }
    function getOutputNativeData(){
        return mOutNativeData_;
    }

}