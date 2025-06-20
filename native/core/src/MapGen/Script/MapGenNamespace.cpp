#include "MapGenNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

#include "PluginBaseSingleton.h"
#include "MapGen/MapGen.h"
#include "System/Util/PathUtils.h"

#include "MapGen/MapGenScriptStep.h"
#include "MapGen/MapGenScriptClient.h"
#include "MapGen/Script/MapGenScriptManager.h"

#include "GameCoreLogger.h"

namespace ProceduralExplorationGameCore{

    SQInteger MapGenNamespace::registerStep(HSQUIRRELVM vm){
        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const SQChar *stepName;
        sq_getstring(vm, 3, &stepName);

        std::string outPath;
        const SQChar *scriptPath;
        sq_getstring(vm, 4, &scriptPath);
        AV::formatResToPath(scriptPath, outPath);

        MapGen* mapGen = PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        ProceduralExplorationGameCore::CallbackScript* script = manager->loadScript(outPath);
        if(!script){
            std::string e = std::string("Error parsing script at path ") + outPath;
            return sq_throwerror(vm, e.c_str());
        }

        MapGenClient* client = mapGen->getCurrentCollectingMapGenClient();
        MapGenScriptClient* scriptClient = dynamic_cast<MapGenScriptClient*>(client);
        MapGenScriptStep* step = new MapGenScriptStep(stepName, scriptClient, script);
        mapGen->registerStep(idx, step);

        GAME_CORE_INFO("Succesfully registered MapGen step '{}' at idx {}", stepName, idx);

        return 0;
    }

    void MapGenNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, registerStep, "registerStep", 4, ".iss");
    }

}
