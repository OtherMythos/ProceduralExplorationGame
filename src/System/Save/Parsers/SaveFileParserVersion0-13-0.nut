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
        updateData(mDefaultData_);
    }

    #Override
    function updateData(data){
        data.version = getVersionString();
        data.playerHealth <- 200;
        return data;
    }

});