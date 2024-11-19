#include "MergeSmallRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    MergeSmallRegionsMapGenStep::MergeSmallRegionsMapGenStep(){

    }

    MergeSmallRegionsMapGenStep::~MergeSmallRegionsMapGenStep(){

    }

    void MergeSmallRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        for(RegionData& d : mapData->regionData){
            if(d.total >= 200) continue;

            //Don't attempt to merge small main regions, so the session can guarantee having the correct number.
            if(d.meta & static_cast<AV::uint8>(RegionMeta::MAIN_REGION)){
                continue;
            }

            //Go through the edges and check the neighbours for a region
            std::set<RegionId> foundRegions;
            findNeighboursForRegion(mapData, d, foundRegions);

            for(RegionId r : foundRegions){
                //TODO do I need this?
                if(r == 0x0) continue;
                RegionData& sd = mapData->regionData[r];
                if(d.id == sd.id) continue;
                mergeRegionData(mapData, d, sd);

                //Just take the first value for now.
                break;
            }
        }
    }

}
