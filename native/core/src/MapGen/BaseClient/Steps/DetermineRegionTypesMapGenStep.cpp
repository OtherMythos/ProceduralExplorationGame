#include "DetermineRegionTypesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <array>

namespace ProceduralExplorationGameCore{

    DetermineRegionTypesMapGenStep::DetermineRegionTypesMapGenStep() : MapGenStep("Determine Region Types"){

    }

    DetermineRegionTypesMapGenStep::~DetermineRegionTypesMapGenStep(){

    }

    bool DetermineRegionTypesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        std::vector<RegionId> freeRegions;
        freeRegions.reserve(regionData.size());
        /*
        for(RegionId i = 0; i < static_cast<RegionId>(mapData->ptr<std::vector<RegionData>>("regionData")->size()); i++){
            const RegionData& r = mapData->ptr<std::vector<RegionData>>("regionData")[i];
            if(r.type != RegionType::NONE) continue;

            freeRegions.push_back(i);
        }
         */
        freeRegions.push_back(0);
        freeRegions.push_back(1);
        freeRegions.push_back(2);

        std::vector<RegionId> blacklistedRegions;

        static const std::array regionsToAdd{RegionType::CHERRY_BLOSSOM_FOREST, RegionType::SWAMP, RegionType::DESERT};
        for(RegionType r : regionsToAdd){
            size_t targetIdx = mapGenRandomIndex(freeRegions);
            if(targetIdx >= freeRegions.size()) continue;
            RegionData& rd = regionData[freeRegions[targetIdx]];
            rd.type = r;
            if(r == RegionType::DESERT || r == RegionType::SWAMP){
                rd.meta |= static_cast<AV::uint8>(RegionMeta::EXPANDABLE);
            }

            regionData[freeRegions[targetIdx]].type = r;
            blacklistedRegions.push_back(freeRegions[targetIdx]);
            freeRegions.erase(freeRegions.begin() + targetIdx);
        }

        //Place HOT_SPRING regions
        static const std::array smallRegionsToAdd{RegionType::HOT_SPRINGS};
        for(RegionType r : smallRegionsToAdd){
            std::vector<RegionId> availableRegions;
            for(size_t i = 0; i < regionData.size(); i++){
                RegionId regionId = static_cast<RegionId>(i);
                //Check if this region is blacklisted
                bool isBlacklisted = false;
                for(RegionId blacklistedId : blacklistedRegions){
                    if(blacklistedId == regionId){
                        isBlacklisted = true;
                        break;
                    }
                }
                if(isBlacklisted) continue;

                const RegionData& rd = regionData[regionId];
                if(rd.type == RegionType::NONE){
                    if(rd.total > 500 && rd.total < 2000){
                        availableRegions.push_back(regionId);
                    }
                }
            }

            if(!availableRegions.empty()){
                size_t targetIdx = mapGenRandomIndex(availableRegions);
                RegionData& rd = regionData[availableRegions[targetIdx]];
                rd.type = r;
                rd.meta |= static_cast<AV::uint8>(RegionMeta::MAIN_REGION);
                blacklistedRegions.push_back(availableRegions[targetIdx]);
            }
        }

        return true;
    }

}
