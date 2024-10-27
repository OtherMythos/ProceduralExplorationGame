
::VisitedLocationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    mThread_ = null;
    mTargetMap_ = null;
    mChunkManager_ = null;

    mStarted_ = false;

    constructor(targetMap){
        mTargetMap_ = targetMap;
    }

    function provideChunkManager(chunkManager){
        mChunkManager_ = chunkManager;
    }

    #Override
    function processPreparation(){

        if(!mStarted_){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": true, "ended": false});
            _gameCore.beginParseVisitedLocation(mTargetMap_);
            mStarted_ = true;
        }

        local mapClaim = _gameCore.checkClaimParsedVisitedLocation();
        if(mapClaim != null){
            mCurrentPercent_ = 1.0;
            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, {
                "percentage": mCurrentPercent_,
                "name": "done"
            });

            mOutData_ = threadGenerateScene(mTargetMap_, mChunkManager_, mapClaim);
        }else{
        }

        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }
        return mCurrentPercent_ >= 1.0;
    }

    function threadGenerateScene(targetMap, chunkManager, nativeData){
        local mapData = {
            "width": nativeData.getWidth(),
            "height": nativeData.getHeight(),
            "native": nativeData
        };

        local mapsDir = ::BaseHelperFunctions.getMapsDir();

        local path = mapsDir + targetMap + "/scene.avscene";
        local parsedFile = null;
        if(_system.exists(path)){
            printf("Loading scene file with path '%s'", path);
            parsedFile = _scene.parseSceneFile(path);
        }

        //TODO properly give this a name.
        local animationPath = mapsDir + targetMap + "/sceneAnimation.xml";
        if(_system.exists(animationPath)){
            _animation.loadAnimationFile(animationPath);
        }

        local mapMeta = null;
        local metaPath = mapsDir + targetMap + "/meta.json";
        print(metaPath);
        if(_system.exists(metaPath)){
            mapMeta = _system.readJSONAsTable(metaPath);
        }
        if(mapMeta == null){
            mapMeta = {};
        }

        chunkManager.setup(nativeData, 4);
        chunkManager.generateInitialItems();

        local scriptPath = mapsDir + targetMap + "/script.nut";
        local scriptObject = null;
        if(_system.exists(scriptPath)){
            assert(!getroottable().rawin("VisitedWorldScriptObject"));
            _doFile(scriptPath);
            scriptObject = ::VisitedWorldScriptObject;
            getroottable().rawdelete("VisitedWorldScriptObject");
        }

        local outData = {
            "mapData": mapData,
            "parsedSceneFile": parsedFile,
            "width": mapData.width,
            "height": mapData.height,
            "scriptObject": scriptObject,
            "native": nativeData,
            "meta": mapMeta
        };
        return outData;
    }

    function getOutputData(){
        return mOutData_;
    }

}