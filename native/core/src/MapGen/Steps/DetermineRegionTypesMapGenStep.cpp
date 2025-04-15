#include "DetermineRegionTypesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <array>

namespace ProceduralExplorationGameCore{

    DetermineRegionTypesMapGenStep::DetermineRegionTypesMapGenStep() : MapGenStep("Determine Region Types"){

    }

    DetermineRegionTypesMapGenStep::~DetermineRegionTypesMapGenStep(){

    }

    void DetermineRegionTypesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionId> freeRegions;
        freeRegions.reserve(mapData->regionData.size());
        /*
        for(RegionId i = 0; i < static_cast<RegionId>(mapData->regionData.size()); i++){
            const RegionData& r = mapData->regionData[i];
            if(r.type != RegionType::NONE) continue;

            freeRegions.push_back(i);
        }
         */
        freeRegions.push_back(0);
        freeRegions.push_back(1);
        freeRegions.push_back(2);

        static const std::array regionsToAdd{RegionType::CHERRY_BLOSSOM_FOREST, RegionType::EXP_FIELDS, RegionType::DESERT};
        for(RegionType r : regionsToAdd){
            size_t targetIdx = mapGenRandomIndex(freeRegions);
            if(targetIdx >= freeRegions.size()) continue;
            RegionData& rd = mapData->regionData[freeRegions[targetIdx]];
            rd.type = r;
            if(r == RegionType::DESERT){
                rd.meta |= static_cast<AV::uint8>(RegionMeta::EXPANDABLE);
            }

            mapData->regionData[freeRegions[targetIdx]].type = r;
            freeRegions.erase(freeRegions.begin() + targetIdx);
        }

    }

}
