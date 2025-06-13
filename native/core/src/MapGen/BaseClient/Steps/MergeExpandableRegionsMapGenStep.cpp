#include "MergeExpandableRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    MergeExpandableRegionsMapGenStep::MergeExpandableRegionsMapGenStep() : MapGenStep("Merge Expandable Regions"){

    }

    MergeExpandableRegionsMapGenStep::~MergeExpandableRegionsMapGenStep(){

    }

    void MergeExpandableRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        for(RegionData& r : regionData){
            if(r.meta & static_cast<AV::uint8>(RegionMeta::EXPANDABLE)){
                std::set<RegionId> foundRegions;
                findNeighboursForRegion(mapData, r, foundRegions);
                for(RegionId rId : foundRegions){
                    if(rId == r.id || rId == 0x0) continue;
                    mergeRegionData(mapData, regionData[rId], r);
                }
            }
        }
    }

}
