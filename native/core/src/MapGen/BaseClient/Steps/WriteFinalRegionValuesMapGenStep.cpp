#include "WriteFinalRegionValuesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "Util/FloodFill.h"

#include <cassert>
#include <cmath>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    WriteFinalRegionValuesMapGenStep::WriteFinalRegionValuesMapGenStep() : MapGenStep("Write Final Region Values"){

    }

    WriteFinalRegionValuesMapGenStep::~WriteFinalRegionValuesMapGenStep(){

    }

    bool WriteFinalRegionValuesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        AV::uint8* regionPtr = REGION_PTR_FOR_COORD(mapData, 0);
        for(int i = 0; i < mapData->width * mapData->height; i++){
            *regionPtr = REGION_ID_WATER;
            regionPtr += 4;
        }

        //Write the region ids to the buffer.
        for(const RegionData& r : regionData){
            for(WorldPoint p : r.coords){
                *REGION_PTR_FOR_COORD(mapData, p) = r.id;
            }
        }

        return true;
    }

}
