#include "MapGenScriptManager.h"

#include "System/Util/PathUtils.h"
#include "Scripting/Script/CallbackScript.h"
#include "MapGenScriptVM.h"
#include "CallbackScript.h"

#include "GameCoreLogger.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptManager::MapGenScriptManager(){
        mVM = new MapGenScriptVM();
        mVM->setup();
    }

    MapGenScriptManager::~MapGenScriptManager(){

    }

    CallbackScript* MapGenScriptManager::loadScript(const std::string& scriptPath){
        if(!AV::fileExists(scriptPath)) return 0;

        CallbackScript* loadedScript = new CallbackScript();
        loadedScript->initialise(mVM);
        loadedScript->release();
        if(!loadedScript->prepareRaw(scriptPath.c_str())){
            delete loadedScript;
            return 0;
        }

        return loadedScript;
    }
}
