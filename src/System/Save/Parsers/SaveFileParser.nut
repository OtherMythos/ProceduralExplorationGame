::SaveFileParser <- class{

    mVersion_ = 0;

    mJSONSchema_ = null;

    constructor(max, min, patch){
        mVersion_ = ::SaveHelpers.hashVersion(max, min, patch);
    }

    /**
     * Read a file from the disk, returning the parsed data as a table
     * @param path
     */
    function readMetaFile(path){
        local json = null;
        try{
            json = _system.readJSONAsTable(path);
        }catch(e){
            //TODO error codes.
            throw e;
        }

        local result = performSchemaCheck(json);
        if(!result) throw "Failed schema check";

        return json;
    }

    function writeMetaFile(path, data){
        printf("Writing to path '%s'", path);
        _system.writeJsonAsFile(path, data);

        //Try and read it back and check it passes the verification.
        local readValue = readMetaFile(path);
    }

    function performSchemaCheckTable_(table, schemaTable){
        //Loop through both schemaTable and checking table to ensure no keys are missing.
        foreach(c,i in schemaTable){
            if(!table.rawin(c)) return false;
        }
        foreach(c,i in table){
            if(!schemaTable.rawin(c)) return false;

            //Determine if the json schema includes a table.
            local checkType = schemaTable.rawget(c);
            local schemaType = typeof checkType;
            schemaType = schemaType == OBJECT_TYPE.TABLE ? OBJECT_TYPE.TABLE : checkType;

            local localType = (typeof i);
            if(localType != schemaType) return false;
            if(localType == OBJECT_TYPE.TABLE){
                if(!performSchemaCheckTable_(i, checkType)) return false;
            }
        }

        return true;
    }
    function performSchemaCheck(data){
        assert(mJSONSchema_ != null);
        return performSchemaCheckTable_(data, mJSONSchema_);
    }

    /**
     * Update the provided data from the previous file format to this one.
     * These operations should be able to be chained together to update an old save to the latest format.
     * @param data input data formatted in the old format.
     * @returns outData Converted data in a format suitable for this parser.
     */
    function updateData(data){
        return data;
    }

    function getHashVersion(){
        return mVersion_;
    }


};