::SaveManager.registerParser(0, 15, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 15, 0);
    }

    function setup(){
        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.foundArtifacts <- OBJECT_TYPE.ARRAY;
        updateData(mDefaultData_);
    }

    #Override
    function updateData(data){
        data.version = getVersionString();
        data.foundArtifacts <- [];
        return data;
    }

});
