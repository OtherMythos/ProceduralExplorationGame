::SaveManager.mParsers_.append(class extends SaveFileParser{
    constructor(){
        base.constructor(0, 1, 0);
    }

    #Override
    function readMetaFile(path){
        local data = base.readMetaFile(path);

        //TODO validate the entries with a JSON schema.

        return data;
    }
});