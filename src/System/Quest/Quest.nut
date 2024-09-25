::Quest <- class{

    mName_ = null;

    mEntries_ = null;
    mEntriesLookup_ = null;

    mValues_ = null;

    constructor(name, numValues=0){
        mName_ = name;
        mEntries_ = [];
        mEntriesLookup_ = {};
        mValues_ = array(numValues)

        setup();
    }

    function setup(){

    }

    function getName(){
        return mName_;
    }

    /**
     * Register a new entry for this quest.
     * Each entry takes a single JSON entry in the serialised save file.
     * Into entries, values are stored, in a bit packing approach. This helps reduce the number of entries that need to be stored.
     * @param name
     * @param string
     */
    function registerEntry(name, string=false){
        local idx = mEntries_.len();
        mEntries_.append({
            "name": name,
            "string": string,
            "data": 0
        });
        mEntriesLookup_.rawset(name, idx);

        return idx;
    }

    /**
     * Return an entry table for the serialisation system.
     */
    function getTable(){
        local outTable = {};

        foreach(c,i in mEntriesLookup_){
            outTable.rawset(c, mEntries_[i].data);
        }

        return outTable;
    }

    function registerValue(id, entry, size, shift){
        local targetEntry = mEntries_[entry];
        mValues_[id] = {
            "size": size,
            "shift": shift,
            "entry": entry
        };
    }

    function readValue(id){
        local value = mValues_[id];
        local data = mEntries_[value.entry].data;
        local clampMask = ((1 << value.size) - 1);
        local foundVal = (data >> value.shift) & clampMask;

        return foundVal;
    }

    function setValue(id, value){
        local v = mValues_[id];
        local e = mEntries_[v.entry];
        local data = e.data;

        local clampMask = ((1 << v.size)-1) << v.shift;
        e.data = data | ((value << v.shift) & clampMask);
    }

    function setBoolean(id, value){
        if(mValues_[id].size != 1){
            throw "Requested value is not a boolean.";
        }
        setValue(id, value ? 1 : 0);
    }

    function readBoolean(id){
        local val = readValue(id);
        return val == 1;
    }

};