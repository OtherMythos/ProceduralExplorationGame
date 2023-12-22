::SaveHelpers <- {

    function hashVersion(max, min, patch){
        return ((max << 20) | (min << 10) | patch);
    }

    function readVersionMax(hash){
        return (hash >> 20) & 0x3FF;
    }
    function readVersionMin(hash){
        return (hash >> 10) & 0x3FF;
    }
    function readVersionPatch(hash){
        return hash & 0x3FF;
    }

};

::SaveManager <- class{

    mParsers_ = [];

    constructor(){

    }

    function readSaveAtPath(path){

        if(!_system.exists(path)){
            throw format("Save directory at path '%s' does not exist", path);
        }

        local metaFilePath = path + "/meta.json";
        if(!_system.exists(metaFilePath)){
            throw format("Save meta file at path '%s' does not exist", metaFilePath);
        }

        //Start by reading the version from the meta file.
        local saveTable = null;
        try{
            saveTable = _system.readJSONAsTable(metaFilePath);
        }catch(e){
            //TODO when proper error codes are here return them there.
            throw e
        }
        //Check a valid version can be read.
        if(!("version" in saveTable)){
            throw "Could not read version header from save";
        }
        //Use the version to determine which parser to use.

        local hash = parseVersionStringToHash_(saveTable.version);
        local parserChain = findParserChain_(hash, mParsers_);

        assert(parserChain.len() > 0);

        local parser = parserChain[0]();
        printf("Reading meta file at path '%s'", metaFilePath);
        local data = parser.readMetaFile(metaFilePath);

        if(parserChain.len() > 1){
            for(local i = 0; i < parserChain.len()-1; i++){
                local parser = parserChain[i+1]();
                data = parser.updateData(data);
            }
        }

        return data;
    }

    function writeSaveAtPath(path, data){
        /*
        The writing procedure follows the steps of:
            Write the files to a temporary directory,
            Verify the written files by parsing them again,
            Delete the old save directory and move the new one into its place
        */


        local resolvedPath = _system.resolveResPath(path);
        print("Resolved path " + resolvedPath);
        local filename = _system.getFilenamePath(resolvedPath);
        print("filename " + filename);
        local targetOutDir = filename + "-temp";
        local oldOutDir = filename + "-old";
        //local tempSaveDir = _system.getParentPath(resolvedPath);
        //print("parent path " + tempSaveDir);

        local oldWritePath = "user://" + oldOutDir;
        local backupWritePath = "user://" + targetOutDir;
        if(_system.exists(backupWritePath)){
            throw "A temporary directory already exists!"
        }
        if(_system.exists(oldWritePath)){
            throw "Old directory for this save already exists!"
        }
        _system.mkdir(backupWritePath);

        local recentParser = getMostRecentParser();
        recentParser.writeMetaFile(backupWritePath + "/meta.json", data);

        //Now all that's done perform the atomic operations to setup the new save.
        _system.rename(path, oldWritePath);
        _system.rename(backupWritePath, path);
        //Now remove the old directory.
        _system.removeAll(oldWritePath);
    }

    function parseVersionStringToHash_(versionString){
        local result = split(versionString, ".");
        //TODO error checking
        for(local i = 0; i < result.len(); i++){
            result[i] = result[i].tointeger();
        }

        return ::SaveHelpers.hashVersion(result[0], result[1], result[2]);
    }

    /**
     * For a version hash find the chain of parsers that have to be traversed until the most recent parser is found.
     * @param versionHash
     */
    function findParserChain_(versionHash, parsers){
        local minIdx = findMinimumParser_(versionHash, parsers);
        local outArray = [];
        for(local i = 0; i < parsers.len() - minIdx; i++){
            outArray.append(parsers[minIdx + i]);
        }
        return outArray;
    }

    function findMinimumParser_(versionHash, parsers){
        local highestVal = 0;
        for(local i = 0; i < parsers.len(); i++){
            local parserHash = parsers[i].getHashVersion();
            if(parserHash == versionHash) return i;
            if(parserHash >= versionHash) return highestVal;
            highestVal = i;
        }

        return highestVal;
    }

    function getMostRecentParser(){
        return mParsers_[mParsers_.len()-1]();
    }


};

local targetPath = _system.getParentPath(getstackinfos(1).src);
_doFile(format("%s/SaveConstants.nut", targetPath));

function registerSaveParser(max, min, patch){
    local targetPath = _system.getParentPath(getstackinfos(1).src);
    _doFile(format("%s/Parsers/SaveFileParserVersion%i-%i-%i.nut", targetPath, max, min, patch));
}

registerSaveParser(0, 1, 0);