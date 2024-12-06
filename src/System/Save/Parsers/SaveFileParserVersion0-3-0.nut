::SaveManager.registerParser(0, 3, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 3, 0);
    }

    function setup(){
        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.inventory <- OBJECT_TYPE.ARRAY;
        mJSONSchema_.playerEquipped <- OBJECT_TYPE.ARRAY;
        updateData(mDefaultData_);
    }

    function checkIntegerForArray(a){
        foreach(c,i in a){
            if(
                typeof i != "integer" ||
                (i < 0 || i >= ItemId.MAX)
            ){
                a[c] = null;
                continue;
            }
        }
    }
    #Override
    function performDataCheck(json){
        //Ensure the inventory and player equipped array is the correct size.
        ensureArrayToLength(json.playerEquipped, EquippedSlotTypes.MAX);
        ensureArrayToLength(json.inventory, 35);

        checkIntegerForArray(json.playerEquipped);
        checkIntegerForArray(json.inventory);

        return true;
    }

    #Override
    function updateData(data){
        //TODO find some proper way to ensure inventory size.
        data.inventory <- array(35, null);
        data.playerEquipped <- array(EquippedSlotTypes.MAX, null);
        data.version = getVersionString();
        return data;
    }

});