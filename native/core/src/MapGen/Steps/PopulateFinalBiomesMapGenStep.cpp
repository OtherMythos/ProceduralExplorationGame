#include "PopulateFinalBiomesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    PopulateFinalBiomesMapGenStep::PopulateFinalBiomesMapGenStep(){

    }

    PopulateFinalBiomesMapGenStep::~PopulateFinalBiomesMapGenStep(){

    }

    void PopulateFinalBiomesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        int div = 4;
        int divHeight = input->height / div;
        for(int i = 0; i < 4; i++){
            PopulateFinalBiomesMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, input->width, i * divHeight + divHeight);
        }
    }

    PopulateFinalBiomesMapGenJob::PopulateFinalBiomesMapGenJob(){

    }

    PopulateFinalBiomesMapGenJob::~PopulateFinalBiomesMapGenJob(){

    }

    void PopulateFinalBiomesMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const WorldPoint wrappedStartPoint = WRAP_WORLD_POINT(xa, ya);
        AV::uint32* fullSecondaryVoxPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, wrappedStartPoint);
        AV::uint32* fullVoxPtr = FULL_PTR_FOR_COORD(mapData, wrappedStartPoint);
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                AV::uint32* fullVoxPtrWrite = fullVoxPtr;
                const AV::uint32 fullVox = *fullVoxPtr;
                const AV::uint32 fullSecondaryVox = *fullSecondaryVoxPtr;
                fullSecondaryVoxPtr++;
                fullVoxPtr++;
                AV::uint8 altitude = fullVox & 0xFF;
                if(altitude < mapData->seaLevel){
                    continue;
                }

                AV::uint8 moisture = fullSecondaryVox & 0xFF;
                AV::uint8 flags = (fullVox >> 8) & ~MAP_VOXEL_MASK;
                RegionId regionId = (fullSecondaryVox >> 8) & 0xFF;

                const Biome& b = Biome::getBiomeForId(mapData->regionData[regionId].type);

                Biome::PlaceObjectFunction placeFunc = b.getPlacementFunction();
                assert(placeFunc != 0);
                (*placeFunc)(mapData->placedItems, mapData, x, y, altitude, regionId, flags, moisture);

                Biome::DetermineVoxFunction voxFunc = b.getVoxFunction();
                assert(voxFunc != 0);
                MapVoxelTypes finalVox = (*voxFunc)(altitude, moisture, mapData);
                *(reinterpret_cast<AV::uint8*>(fullVoxPtrWrite)+1) |= (static_cast<AV::uint8>(finalVox) & static_cast<AV::uint8>(MAP_VOXEL_MASK));

                Biome::DetermineAltitudeFunction altFunc = b.getAltitudeFunction();
                assert(altFunc != 0);
                AV::uint8 finalAltitude = (*altFunc)(altitude, moisture, x, y, mapData);
                *(reinterpret_cast<AV::uint8*>(fullVoxPtrWrite)) = finalAltitude;
            }
        }
    }

}
