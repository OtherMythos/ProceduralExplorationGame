#include "RecalculateRegionAltitudeMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientHelpers.h"
#include "MapGen/Biomes.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    RecalculateRegionAltitudeMapGenStep::RecalculateRegionAltitudeMapGenStep() : MapGenStep("Recalculate Region Altitude"){

    }

    RecalculateRegionAltitudeMapGenStep::~RecalculateRegionAltitudeMapGenStep(){

    }

    bool RecalculateRegionAltitudeMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>* regionData = mapData->ptr<std::vector<RegionData>>("regionData");

        //Loop through regions and find those needing altitude recalculation
        for(RegionData& region : (*regionData)){
            if(region.meta & static_cast<AV::uint8>(RegionMeta::NEEDS_ALTITUDE_RECALCULATION)){
                region.meta &= ~static_cast<AV::uint8>(RegionMeta::NEEDS_ALTITUDE_RECALCULATION); //Clear the flag

                //Skip if region has no coordinates
                if(region.coords.empty()) continue;

                calculateAndApplyBiomeAltitudeForRegion(mapData, region);
            }
        }

        return true;
    }

}
