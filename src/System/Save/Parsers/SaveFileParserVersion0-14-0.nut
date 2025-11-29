::SaveManager.registerParser(0, 14, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 14, 0);
    }

    function setup(){
        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.bankCoins <- OBJECT_TYPE.INTEGER;
        mJSONSchema_.storage <- OBJECT_TYPE.ARRAY;
        updateData(mDefaultData_);
    }

    #Override
    function updateData(data){
        data.version = getVersionString();
        data.bankCoins <- 0;
        data.storage <- array(35, null);
        return data;
    }

});