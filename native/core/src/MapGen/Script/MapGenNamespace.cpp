#include "MapGenNamespace.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

#include "PluginBaseSingleton.h"
#include "MapGen/MapGen.h"

#include "MapGen/MapGenScriptStep.h"

#include "GameCoreLogger.h"

namespace ProceduralExplorationGameCore{

    SQInteger MapGenNamespace::registerStep(HSQUIRRELVM vm){
        SQInteger idx;
        sq_getinteger(vm, 2, &idx);

        const SQChar *stepName;
        sq_getstring(vm, 3, &stepName);

        GAME_CORE_INFO("Registering MapGen step '{}' at idx {}", stepName, idx);

        MapGen* mapGen = PluginBaseSingleton::getMapGen();
        assert(mapGen);
        if(!mapGen->isFinished()){
            return sq_throwerror(vm, "Map gen is already processing a map generation");
        }

        MapGenScriptStep* step = new MapGenScriptStep(stepName);
        mapGen->registerStep(idx, step);

        return 0;
    }

    void MapGenNamespace::setupNamespace(HSQUIRRELVM vm){
        AV::ScriptUtils::addFunction(vm, registerStep, "registerStep", 3, ".is");
    }

}
