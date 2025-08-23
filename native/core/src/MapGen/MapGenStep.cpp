#include "MapGen/MapGenStep.h"

#include <thread>

namespace ProceduralExplorationGameCore{

    MapGenStep::MapGenStep(const std::string& name)
        : mName(name),
        mMarkerStep(false) {

    }

    MapGenStep::~MapGenStep(){

    }

    bool MapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));

        return true;
    }

    std::string MapGenStep::getName() const{
        return mName;
    }

}
