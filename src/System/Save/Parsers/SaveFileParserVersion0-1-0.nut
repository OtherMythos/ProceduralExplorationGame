::SaveManager.mParsers_.append(class extends SaveFileParser{
    constructor(){
        base.constructor(0, 1, 0);

        mJSONSchema_ = {
            "version": OBJECT_TYPE.STRING,
            "versionCount": OBJECT_TYPE.INTEGER,
            "meta": OBJECT_TYPE.STRING,

            "playerEXP": OBJECT_TYPE.INTEGER,
            "playerCoins": OBJECT_TYPE.INTEGER,

            "playtimeSeconds": OBJECT_TYPE.INTEGER
        };
    }

    #Override
    function readMetaFile(path){
        local data = base.readMetaFile(path);

        return data;
    }
});