::SaveManager.registerParser(0, 17, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 17, 0);
    }

    function setup(){
        local prev = getPreviousParser();
        assert(prev != null);
        mJSONSchema_ = clone prev.mJSONSchema_;
        mDefaultData_ = clone prev.mDefaultData_;

        mJSONSchema_.specialMoves <- OBJECT_TYPE.ARRAY;
        updateData(mDefaultData_);
    }

    #Override
    function updateData(data){
        data.version = getVersionString();
        //Migrate integer item arrays from previous format to string keys.
        data.inventory = itemArrayToStrings_(data.inventory);
        data.playerEquipped = itemArrayToStrings_(data.playerEquipped);
        data.storage = itemArrayToStrings_(data.storage);
        data.specialMoves <- array(4, "NONE");
        return data;
    }

    //Convert an array of integer ItemIds to serialisable string keys.
    //Null slots remain null.
    function itemArrayToStrings_(a){
        local out = clone a;
        foreach(c, i in out){
            if(i == null) continue;
            out[c] = ::ItemIdNames[i];
        }
        return out;
    }

    #Override
    function performDataCheck(json){
        ensureArrayToLength(json.playerEquipped, EquippedSlotTypes.MAX);
        ensureArrayToLength(json.inventory, 35);
        ensureArrayToLength(json.storage, 35);
        ensureArrayToLength(json.specialMoves, 4, "NONE");
        return true;
    }
});
