#include "MapGenStep.h"

#include <thread>

namespace ProceduralExplorationGameCore{

    MapGenStep::MapGenStep(const std::string& name)
        : mName(name) {

    }

    MapGenStep::~MapGenStep(){

    }

    void MapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }

    std::string MapGenStep::getName() const{
        return mName;
    }

}
