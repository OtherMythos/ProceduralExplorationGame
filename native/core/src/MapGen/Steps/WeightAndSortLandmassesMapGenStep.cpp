#include "WeightAndSortLandmassesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    WeightAndSortLandmassesMapGenStep::WeightAndSortLandmassesMapGenStep() : MapGenStep("Weight And Sort Landmasses"){

    }

    WeightAndSortLandmassesMapGenStep::~WeightAndSortLandmassesMapGenStep(){

    }

    bool sortFunction(FloodFillEntry* i, FloodFillEntry* j) { return (i->total > j->total); }

    void WeightAndSortLandmassesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::sort(mapData->landData.begin(), mapData->landData.end(), sortFunction);

        std::vector<LandId> weightedLand;
        weightedLand.resize(100);

        size_t totalLand = 0;
        for(const FloodFillEntry* i : mapData->landData){
            totalLand += i->total;
        }

        int count = 0;
        //Head through the list backwards.
        //Smaller landmasses should be at the back, ensure that each piece of land gets one entry in the list.
        //In this case the smaller landmasses will steal from the largest landmass.
        int startIdx = mapData->landData.size() > 100 ? 100 : static_cast<int>(mapData->landData.size()-1);
        for(int i = startIdx; i >= 0; i--){
            weightedLand[count] = i;
            count++;
            //Drop out if the array is populated.
            if(count >= 100){
                //Assuming we stop on the largest landmass.
                assert(i == 0);
                break;
            }
        }

        workspace->landWeighted = std::move(weightedLand);
    }
}
