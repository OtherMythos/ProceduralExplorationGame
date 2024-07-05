#include "MapGenStep.h"

#include <thread>

namespace ProceduralExplorationGameCore{

    MapGenStep::MapGenStep(){

    }

    MapGenStep::~MapGenStep(){

    }

    void MapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData){
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }

}
