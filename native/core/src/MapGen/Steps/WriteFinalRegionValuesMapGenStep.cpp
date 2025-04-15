#include "WriteFinalRegionValuesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "Util/FloodFill.h"

#include <cassert>
#include <cmath>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    WriteFinalRegionValuesMapGenStep::WriteFinalRegionValuesMapGenStep() : MapGenStep("Write Final Region Values"){

    }

    WriteFinalRegionValuesMapGenStep::~WriteFinalRegionValuesMapGenStep(){

    }

    void WriteFinalRegionValuesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        AV::uint8* regionPtr = REGION_PTR_FOR_COORD(mapData, 0);
        for(int i = 0; i < input->width * input->height; i++){
            *regionPtr = 100;
            regionPtr += 4;
        }

        //Write the region ids to the buffer.
        for(const RegionData& r : mapData->regionData){
            for(WorldPoint p : r.coords){
                *REGION_PTR_FOR_COORD(mapData, p) = r.id;
            }
        }
    }

}
