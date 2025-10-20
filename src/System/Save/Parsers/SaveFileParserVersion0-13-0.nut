::SaveManager.registerParser(0, 13, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 13, 0);
    }

    function setup(){
        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.playerHealth <- OBJECT_TYPE.INTEGER;
        mJSONSchema_.overworldDiscovered <- OBJECT_TYPE.ARRAY;
        updateData(mDefaultData_);
    }

    #Override
    function updateData(data){
        data.version = getVersionString();
        data.playerHealth <- 200;
        data.overworldDiscovered <- array(MAX_OVERWORLD_REGIONS, 0);
        return data;
    }

});