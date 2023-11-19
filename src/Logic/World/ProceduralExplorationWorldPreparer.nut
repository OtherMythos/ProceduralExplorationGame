
::ProceduralExplorationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    mThread_ = null;

    constructor(){

    }

    #Override
    function processPreparation(){
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
    }

    function resetSessionGenMap(){
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

        return outData;
    }

    function getOutputData(){
        return mOutData_;
    }

}