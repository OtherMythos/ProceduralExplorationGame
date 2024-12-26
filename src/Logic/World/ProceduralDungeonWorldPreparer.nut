
::ProceduralDungeonWorldPreparer <- class extends ::WorldPreparer{

    mInputData_ = null;
    mOutData_ = null;

    mThread_ = null;

    constructor(data=null){
        mInputData_ = data;
    }

    #Override
    function processPreparation(){
        assert(mCurrentPercent_ < 1.0);

        local gen = ::DungeonGen();
        if(mInputData_ == null || mInputData_.len() == 0){
            mInputData_ = {
                "width": 50,
                "height": 50,
                "dungeonType": ProceduralDungeonTypes.CATACOMB,
                "seed": _random.randInt(1000)
            };
        }
        local outData = gen.generate(mInputData_);

        mOutData_ = outData;
        mCurrentPercent_ = 1.0;

        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }
        return mCurrentPercent_ >= 1.0;
    }

    function getOutputData(){
        return mOutData_;
    }

}