#include "DetermineRegionTypesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <array>

namespace ProceduralExplorationGameCore{

    DetermineRegionTypesMapGenStep::DetermineRegionTypesMapGenStep(){

    }

    DetermineRegionTypesMapGenStep::~DetermineRegionTypesMapGenStep(){

    }

    void DetermineRegionTypesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionId> freeRegions;
        freeRegions.reserve(mapData->regionData.size());
        for(RegionId i = 0; i < static_cast<RegionId>(mapData->regionData.size()); i++){
            const RegionData& r = mapData->regionData[i];
            if(r.type != RegionType::NONE) continue;

            freeRegions.push_back(i);
        }

        static const std::array regionsToAdd{RegionType::CHERRY_BLOSSOM_FOREST, RegionType::EXP_FIELDS};
        for(RegionType r : regionsToAdd){
            size_t targetIdx = mapGenRandomIndex(freeRegions);
            if(targetIdx <= freeRegions.size()) continue;
            mapData->regionData[freeRegions[targetIdx]].type = r;
            freeRegions.erase(freeRegions.begin() + targetIdx);
        }

    }

}
