#include "PlaceItemsForBiomesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    PlaceItemsForBiomesMapGenStep::PlaceItemsForBiomesMapGenStep() : MapGenStep("Place Items For Biomes"){

    }

    PlaceItemsForBiomesMapGenStep::~PlaceItemsForBiomesMapGenStep(){

    }

    bool PlaceItemsForBiomesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            PlaceItemsForBiomesMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight);
        }

        return true;
    }

    PlaceItemsForBiomesMapGenJob::PlaceItemsForBiomesMapGenJob(){

    }

    PlaceItemsForBiomesMapGenJob::~PlaceItemsForBiomesMapGenJob(){

    }

    void PlaceItemsForBiomesMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));
        std::vector<PlacedItemData>& placedItems = (*mapData->ptr<std::vector<PlacedItemData>>("placedItems"));

        const WorldPoint wrappedStartPoint = WRAP_WORLD_POINT(xa, ya);
        AV::uint32* fullSecondaryVoxPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, wrappedStartPoint);
        AV::uint32* fullTertiaryVoxPtr = FULL_PTR_FOR_COORD_TERTIARY(mapData, wrappedStartPoint);
        AV::uint32* fullVoxPtr = FULL_PTR_FOR_COORD(mapData, wrappedStartPoint);
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                AV::uint32* fullVoxPtrWrite = fullVoxPtr;
                const AV::uint32 fullVox = *fullVoxPtr;
                const AV::uint32 fullSecondaryVox = *fullSecondaryVoxPtr;
                const AV::uint32 fullTertiaryVox = *fullTertiaryVoxPtr;
                fullSecondaryVoxPtr++;
                fullTertiaryVoxPtr++;
                fullVoxPtr++;
                AV::uint8 altitude = fullVox & 0xFF;
                if(altitude < seaLevel){
                    //continue;
                }
                if(fullTertiaryVox & DO_NOT_PLACE_ITEMS_VOXEL_FLAG){
                    continue;
                }
                if(fullTertiaryVox & RIVER_VOXEL_FLAG){
                    continue;
                }

                AV::uint8 moisture = fullSecondaryVox & 0xFF;
                AV::uint16 flags = static_cast<AV::uint16>(fullTertiaryVox & 0xFFFF);
                RegionId regionId = (fullSecondaryVox >> 8) & 0xFF;
                AV::uint8 regionDistance = (fullSecondaryVox >> 16) & 0xFF;

                if(regionId >= regionData.size()) continue;
                const Biome& b = Biome::getBiomeForId(regionData[regionId].type);

                Biome::PlaceObjectFunction placeFunc = b.getPlacementFunction();
                assert(placeFunc != 0);
                (*placeFunc)(placedItems, mapData, x, y, altitude, regionId, flags, moisture, regionDistance);
            }
        }
    }

}
