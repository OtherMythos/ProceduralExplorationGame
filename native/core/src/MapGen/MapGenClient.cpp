#include "MapGenClient.h"

namespace ProceduralExplorationGameCore{
    MapGenClient::MapGenClient(const std::string& name) : mName(name) {

    }

    MapGenClient::~MapGenClient(){

    }

    void MapGenClient::populateSteps(std::vector<MapGenStep*>& steps){

    }

    void MapGenClient::notifyRegistered(HSQUIRRELVM vm){

    }

    void MapGenClient::notifyBegan(const ExplorationMapInputData* input){

    }

    void MapGenClient::notifyEnded(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

    }

    bool MapGenClient::notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData){
        return false;
    }

    void MapGenClient::destroyMapData(ExplorationMapData* mapData){

    }
}
