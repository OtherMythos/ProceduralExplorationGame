::SaveFileParser <- class{

    mVersion_ = 0;

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

        return json;
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