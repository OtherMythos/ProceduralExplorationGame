#include "PlaceItemsForBiomesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    PlaceItemsForBiomesMapGenStep::PlaceItemsForBiomesMapGenStep() : MapGenStep("Place Items For Biomes"){

    }

    PlaceItemsForBiomesMapGenStep::~PlaceItemsForBiomesMapGenStep(){

    }

    void PlaceItemsForBiomesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            PlaceItemsForBiomesMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight);
        }
    }

    PlaceItemsForBiomesMapGenJob::PlaceItemsForBiomesMapGenJob(){

    }

    PlaceItemsForBiomesMapGenJob::~PlaceItemsForBiomesMapGenJob(){

    }

    void PlaceItemsForBiomesMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

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
                if(altitude < seaLevel){
                    continue;
                }

                AV::uint8 moisture = fullSecondaryVox & 0xFF;
                AV::uint8 flags = (fullVox >> 8) & ~MAP_VOXEL_MASK;
                RegionId regionId = (fullSecondaryVox >> 8) & 0xFF;

                const Biome& b = Biome::getBiomeForId(regionData[regionId].type);

                Biome::PlaceObjectFunction placeFunc = b.getPlacementFunction();
                assert(placeFunc != 0);
                (*placeFunc)(mapData->placedItems, mapData, x, y, altitude, regionId, flags, moisture);
            }
        }
    }

}
