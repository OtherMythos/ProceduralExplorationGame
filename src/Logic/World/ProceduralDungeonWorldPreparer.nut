
::ProceduralDungeonWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    mThread_ = null;

    constructor(){

    }

    #Override
    function processPreparation(){
        assert(mCurrentPercent_ < 1.0);

        local gen = ::DungeonGen();
        local data = {
            "width": 50,
            "height": 50,
        };
        local outData = gen.generate(data);

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