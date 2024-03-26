::SaveManager.registerParser(0, 3, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 3, 0);

        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.inventory <- OBJECT_TYPE.ARRAY;
        mDefaultData_.inventory <- array(35, null)
        mDefaultData_.version = getVersionString();
        //print(_prettyPrint(mJSONSchema_));
    }

    #Override
    function performDataCheck(json){
        local inventory = mDefaultData_.inventory;
        foreach(c,i in inventory){
            if(
                typeof i != "integer" ||
                (i < 0 || i >= ItemId.MAX)
            ){
                inventory[c] = null;
                continue;
            }
        }

        return true;
    }

    #Override
    function updateData(data){
        //TODO find some proper way to ensure inventory size.
        data.inventory <- array(35, null);
        data.version = getVersionString();
        return data;
    }

});