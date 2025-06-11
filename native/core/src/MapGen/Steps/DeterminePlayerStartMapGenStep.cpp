#include "DeterminePlayerStartMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    DeterminePlayerStartMapGenStep::DeterminePlayerStartMapGenStep() : MapGenStep("Determine Player Start"){

    }

    DeterminePlayerStartMapGenStep::~DeterminePlayerStartMapGenStep(){

    }

    void DeterminePlayerStartMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        if(mapData->landData.empty()){
            mapData->playerStart = WRAP_WORLD_POINT(input->uint32("width")/2, input->uint32("height")/2);
            return;
        }
        const FloodFillEntry* landData = mapData->landData[0];
        WorldPoint point = findRandomPointInLandmass(landData);
        mapData->playerStart = point;
    }

}
