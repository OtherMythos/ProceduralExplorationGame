#include "DeterminePlayerStartMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    DeterminePlayerStartMapGenStep::DeterminePlayerStartMapGenStep(){

    }

    DeterminePlayerStartMapGenStep::~DeterminePlayerStartMapGenStep(){

    }

    void DeterminePlayerStartMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const FloodFillEntry* landData = mapData->landData[0];
        WorldPoint point = findRandomPointInLandmass(landData);
        mapData->playerStart = point;
    }

}
