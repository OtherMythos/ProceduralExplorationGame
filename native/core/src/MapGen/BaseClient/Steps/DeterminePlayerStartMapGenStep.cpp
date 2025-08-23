#include "DeterminePlayerStartMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    DeterminePlayerStartMapGenStep::DeterminePlayerStartMapGenStep() : MapGenStep("Determine Player Start"){

    }

    DeterminePlayerStartMapGenStep::~DeterminePlayerStartMapGenStep(){

    }

    bool DeterminePlayerStartMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const std::vector<FloodFillEntry*>& landData = (*mapData->ptr<std::vector<FloodFillEntry*>>("landData"));

        if(landData.empty()){
            mapData->worldPoint("playerStart", WRAP_WORLD_POINT(input->uint32("width")/2, input->uint32("height")/2));
            return true;
        }
        const FloodFillEntry* landEntry = landData[0];
        WorldPoint point = findRandomPointInLandmass(landEntry);
        mapData->worldPoint("playerStart", point);

        return true;
    }

}
