#pragma once

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/Biomes.h"

namespace ProceduralExplorationGameCore{

    inline void calculateAndApplyBiomeAltitudeForRegion(ExplorationMapData* mapData, const RegionData& region){
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        const Biome& b = Biome::getBiomeForId(region.type);
        Biome::DetermineAltitudeFunction altFunc = b.getAltitudeFunction();
        assert(altFunc != 0);

        for(WorldPoint p : region.coords){
            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);

            AV::uint32* fullVoxPtr = FULL_PTR_FOR_COORD(mapData, p);
            AV::uint32* fullSecondaryVoxPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, p);

            const AV::uint32 fullVox = *fullVoxPtr;
            const AV::uint32 fullSecondaryVox = *fullSecondaryVoxPtr;

            AV::uint8 altitude = fullVox & 0xFF;
            if(altitude < seaLevel){
                continue;
            }

            AV::uint8 moisture = fullSecondaryVox & 0xFF;
            RegionId regionId = (fullSecondaryVox >> 8) & 0xFF;
            AV::uint8 regionDistance = (fullSecondaryVox >> 16) & 0xFF;

            AV::uint8 finalAltitude = (*altFunc)(altitude, moisture, regionDistance, x, y, mapData);
            *(reinterpret_cast<AV::uint8*>(fullVoxPtr)) = finalAltitude;
        }
    }

}
