#include "MapGenScriptClient.h"

#include "Script/CallbackScript.h"

#include "MapGen/Script/MapGenScriptManager.h"
#include "PluginBaseSingleton.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptClient::MapGenScriptClient(CallbackScript* script)
        : mScript(script){

    }

    MapGenScriptClient::~MapGenScriptClient(){

    }

    static SQObject populateMapTable;
    SQInteger populateNotifyBegan(HSQUIRRELVM vm){

        sq_pushobject(vm, populateMapTable);

        return 2;
    }

    void MapGenScriptClient::populateSteps(std::vector<MapGenStep*>& steps){
        mScript->call("populateSteps");
    }

    void MapGenScriptClient::notifyBegan(const ExplorationMapInputData* input){
        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();

        MapGenScriptVM* scriptVM = manager->getScriptVM();

        HSQUIRRELVM vm = scriptVM->getVM();
        sq_resetobject(&mClientTableObj);
        sq_newtable(vm);
        sq_getstackobj(vm, -1, &mClientTableObj);
        sq_addref(vm, &mClientTableObj);
        sq_pop(vm, 1);

        populateMapTable = mClientTableObj;
        mScript->call("notifyBegan", &populateNotifyBegan);
    }

    void MapGenScriptClient::notifyEnded(ExplorationMapData* mapData){
        populateMapTable = mClientTableObj;
        mScript->call("notifyEnded", &populateNotifyBegan);
    }

    void MapGenScriptClient::notifyClaimed(ExplorationMapData* mapData){
        populateMapTable = mClientTableObj;
        mScript->call("notifyClaimed", &populateNotifyBegan);
    }
}

