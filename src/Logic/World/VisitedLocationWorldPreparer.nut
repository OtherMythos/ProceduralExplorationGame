
::VisitedLocationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    mThread_ = null;
    mTargetMap_ = null;

    constructor(targetMap){
        mTargetMap_ = targetMap;
    }

    #Override
    function processPreparation(){
        local path = "res://assets/maps/" + mTargetMap_ + "/scene.avscene";
        printf("Loading scene file with path '%s'", path);
        local parsedFile = _scene.parseSceneFile(path);

        local fileHandler = ::TerrainChunkFileHandler();
        local mapData = fileHandler.readMapData("testVillage");

        //TODO properly give this a name.
        local path = "res://assets/maps/" + mTargetMap_ + "/sceneAnimation.xml";
        _animation.loadAnimationFile(path);

        mOutData_ = {
            "mapData": mapData,
            "parsedSceneFile": parsedFile,
            "width": mapData.width,
            "height": mapData.height,
        };

        mCurrentPercent_ = 1.0;
        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }

        return true;
    }

    function getOutputData(){
        return mOutData_;
    }

}