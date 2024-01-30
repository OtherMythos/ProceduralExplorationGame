
::VisitedLocationWorldPreparer <- class extends ::WorldPreparer{

    mOutData_ = null;

    mThread_ = null;
    mTargetMap_ = null;
    mChunkManager_ = null;

    constructor(targetMap){
        mTargetMap_ = targetMap;
    }

    function provideChunkManager(chunkManager){
        mChunkManager_ = chunkManager;
    }

    #Override
    function processPreparation(){
        assert(mChunkManager_ != null);

        local susparam = null;

        if(mThread_ == null)
        {
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": true, "ended": false});
            mThread_ = ::newthread(threadGenerateScene);
            susparam = mThread_.call(mTargetMap_, mChunkManager_);
        }

        susparam = mThread_.wakeup();

        if(mThread_.getstatus()=="idle"){
            mOutData_ = susparam;
            mCurrentPercent_ = 1.0;
            mThread_ = null;
            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, {
                "percentage": mCurrentPercent_,
                "name": "done"
            });
        }else{
            mCurrentPercent_ = susparam.percentage;
            print("TERRAIN CHUNK GENERATION" + (mCurrentPercent_ * 100).tointeger() + "% stage: " + susparam.name);

            _event.transmit(Event.WORLD_PREPARATION_GENERATION_PROGRESS, susparam);
        }

        if(mCurrentPercent_ >= 1.0){
            _event.transmit(Event.WORLD_PREPARATION_STATE_CHANGE, {"began": false, "ended": true});
        }

        return mCurrentPercent_ >= 1.0;
    }

    function threadGenerateScene(targetMap, chunkManager){
        local fileHandler = ::TerrainChunkFileHandler();
        local mapData = fileHandler.readMapData(targetMap);

        local path = "res://build/assets/maps/" + targetMap + "/scene.avscene";
        local parsedFile = null;
        if(_system.exists(path)){
            printf("Loading scene file with path '%s'", path);
            parsedFile = _scene.parseSceneFile(path);
        }

        //TODO properly give this a name.
        local animationPath = "res://build/assets/maps/" + targetMap + "/sceneAnimation.xml";
        if(_system.exists(animationPath)){
            _animation.loadAnimationFile(animationPath);
        }

        chunkManager.setup(mapData, 4);
        chunkManager.generateInitialItems();

        local scriptPath = "res://build/assets/maps/" + targetMap + "/script.nut";
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
            "scriptObject": scriptObject
        };
        return outData;
    }

    function getOutputData(){
        return mOutData_;
    }

}