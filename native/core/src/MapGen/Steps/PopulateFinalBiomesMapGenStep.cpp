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

    void PopulateFinalBiomesMapGenJob::processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb){
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
                RegionId regionId = (fullSecondaryVox >> 8) & 0xFF;

                const Biome& b = Biome::getBiomeForId(mapData->regionData[regionId].type);

                Biome::PlaceObjectFunction placeFunc = b.getPlacementFunction();
                assert(placeFunc != 0);
                (*placeFunc)(mapData->placedItems, mapData, x, y, altitude, regionId, moisture);

                Biome::DetermineVoxFunction voxFunc = b.getVoxFunction();
                assert(voxFunc != 0);
                MapVoxelTypes finalVox = (*b.getVoxFunction())(altitude, moisture, mapData);
                *(reinterpret_cast<AV::uint8*>(fullVoxPtrWrite)+1) = static_cast<AV::uint8>(finalVox);
            }
        }
    }

}
