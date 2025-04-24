#include "MapGenScriptClient.h"

#include "Script/CallbackScript.h"

namespace ProceduralExplorationGameCore{
    MapGenScriptClient::MapGenScriptClient(CallbackScript* script)
        : mScript(script){

    }

    MapGenScriptClient::~MapGenScriptClient(){

    }

    void MapGenScriptClient::populateSteps(std::vector<MapGenStep*>& steps){
        mScript->call("populateSteps");
    }

    void MapGenScriptClient::notifyBegan(const ExplorationMapInputData* input){
        mScript->call("notifyBegan");
    }

    void MapGenScriptClient::notifyEnded(ExplorationMapData* mapData){
        mScript->call("notifyEnded");
    }

    void MapGenScriptClient::notifyClaimed(ExplorationMapData* mapData){
        mScript->call("notifyClaimed");
    }
}
