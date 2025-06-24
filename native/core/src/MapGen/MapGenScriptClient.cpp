#include "MapGenScriptClient.h"

#include "Script/CallbackScript.h"

#include "MapGen/Script/MapGenScriptManager.h"
#include "PluginBaseSingleton.h"

#include "Scripting/ScriptNamespace/ScriptUtils.h"

#include "Scripting/SquirrelDeepCopy.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptClient::MapGenScriptClient(CallbackScript* script, const std::string& name)
        : MapGenClient(name), mScript(script){

    }

    MapGenScriptClient::~MapGenScriptClient(){

    }

    static SQObject populateMapTable;
    SQInteger populateNotifyBegan(HSQUIRRELVM vm){

        sq_pushobject(vm, populateMapTable);

        return 2;
    }

    static SQObject notifyRegisteredTable;
    SQInteger populateNotifyRegistered(HSQUIRRELVM vm){

        sq_pushobject(vm, notifyRegisteredTable);
        sq_resetobject(&notifyRegisteredTable);

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

    bool MapGenScriptClient::notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData){
        populateMapTable = mClientTableObj;
        mScript->call("notifyClaimed", &populateNotifyBegan);

        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        MapGenScriptVM* scriptVM = manager->getScriptVM();
        HSQUIRRELVM squirrelVM = scriptVM->getVM();

        sq_pushobject(squirrelVM, mClientTableObj);

        AV::SquirrelDeepCopy copy;
        copy.deepCopyTable(squirrelVM, vm, -2);
        //sq_move(vm, squirrelVM, -1);
        sq_pop(squirrelVM, 1);

        return true;
    }

    void MapGenScriptClient::notifyRegistered(HSQUIRRELVM vm){
        ProceduralExplorationGameCore::MapGenScriptManager* manager = ProceduralExplorationGameCore::PluginBaseSingleton::getScriptManager();
        MapGenScriptVM* scriptVM = manager->getScriptVM();
        HSQUIRRELVM squirrelVM = scriptVM->getVM();

        AV::SquirrelDeepCopy copy;
        copy.deepCopyValue(vm, squirrelVM, -1);

        //I need to grab hold of a reference to the object so I can move it in the stack.
        sq_resetobject(&notifyRegisteredTable);
        sq_getstackobj(squirrelVM, -1, &notifyRegisteredTable);
        sq_addref(squirrelVM, &notifyRegisteredTable);
        sq_pop(squirrelVM, 1);

        mScript->call("notifyRegistered", &populateNotifyRegistered);
    }
}

