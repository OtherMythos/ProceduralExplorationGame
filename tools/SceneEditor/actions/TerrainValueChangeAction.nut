::SceneEditorFramework.Actions[SceneEditorFramework_Action.USER_0] = class extends ::SceneEditorFramework.Action{

    mOldValues_ = null;
    mNewValues_ = null;
    mMapData_ = null;
    mAltitude_ = true;
    mChunkManager_ = null;
    mEffectedChunks_ = null;

    mCurrentAction_ = null;

    constructor(mapData, altitude, chunkManager){
        mOldValues_ = {};
        mNewValues_ = {};
        mEffectedChunks_ = {};
        mMapData_ = mapData;
        mAltitude_ = altitude;
        mChunkManager_ = chunkManager;
    }

    function populateForCoord(x, y, chunkX, chunkY, oldValue, newValue){
        local terrainCoord = (x << 32) | y;
        local chunkCoord = (chunkX << 32) | chunkY;
        if(!mOldValues_.rawin(terrainCoord)){
            mOldValues_.rawset(terrainCoord, oldValue);
        }
        mNewValues_.rawset(terrainCoord, newValue);
        mEffectedChunks_.rawset(chunkCoord, true);
    }

    #Override
    function performAction(){
        perform_(mNewValues_);
    }

    #Override
    function performAntiAction(){
        perform_(mOldValues_);
    }

    function perform_(targetData){
        if(mAltitude_){
            foreach(c,i in targetData){
                local x = (c >> 32) & 0xFFFFFFFF;
                local y = c & 0xFFFFFFFF;
                mMapData_.setAltitudeForCoord(x, y, i)
            }
        }else{
            foreach(c,i in targetData){
                local x = (c >> 32) & 0xFFFFFFFF;
                local y = c & 0xFFFFFFFF;
                mMapData_.setVoxelForCoord(x, y, i)
            }
        }

        foreach(c,i in mEffectedChunks_){
            local x = (c >> 32) & 0xFFFFFFFF;
            local y = c & 0xFFFFFFFF;
            mChunkManager_.recreateChunkItem(x, y);
        }
    }
};
