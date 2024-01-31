::SaveManager.registerParser(0, 1, 0, class extends SaveFileParser{
    constructor(){
        base.constructor(0, 1, 0);

        mJSONSchema_ = {
            "version": OBJECT_TYPE.STRING,
            "versionCount": OBJECT_TYPE.INTEGER,
            "meta": OBJECT_TYPE.STRING,

            "playerEXP": OBJECT_TYPE.INTEGER,
            "playerCoins": OBJECT_TYPE.INTEGER,
            "playerName": OBJECT_TYPE.STRING,

            "playtimeSeconds": OBJECT_TYPE.INTEGER
        };
        mDefaultData_ = {
            "version": "0.1.0",
            "versionCount": 1,
            "meta": "",

            "playerEXP": 0,
            "playerCoins": 0,
            "playerName": "empty",

            "playtimeSeconds": 0
        };
    }

    #Override
    function readMetaFile(path){
        local data = base.readMetaFile(path);

        return data;
    }

    function validatePlayerName(text){
        local value = strip(text);
        value = split(value, "\n", true);
        if(value.len() != 1) return null;
        value = value[0];
        local regex = regexp("^\\w*$");
        if(!regex.match(value)) return null;
        return value;
    }
});