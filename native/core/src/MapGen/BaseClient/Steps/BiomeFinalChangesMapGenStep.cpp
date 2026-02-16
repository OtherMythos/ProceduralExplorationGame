#include "BiomeFinalChangesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    BiomeFinalChangesMapGenStep::BiomeFinalChangesMapGenStep() : MapGenStep("Biome Final Changes"){

    }

    BiomeFinalChangesMapGenStep::~BiomeFinalChangesMapGenStep(){

    }

    bool BiomeFinalChangesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = input->uint32("width");
        const AV::uint32 height = input->uint32("height");

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            BiomeFinalChangesMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight);
        }

        return true;
    }

    BiomeFinalChangesMapGenJob::BiomeFinalChangesMapGenJob(){

    }

    BiomeFinalChangesMapGenJob::~BiomeFinalChangesMapGenJob(){

    }

    void BiomeFinalChangesMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");
        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        const WorldPoint wrappedStartPoint = WRAP_WORLD_POINT(xa, ya);
        AV::uint32* fullSecondaryVoxPtr = FULL_PTR_FOR_COORD_SECONDARY(mapData, wrappedStartPoint);
        AV::uint32* fullTertiaryVoxPtr = FULL_PTR_FOR_COORD_TERTIARY(mapData, wrappedStartPoint);
        AV::uint32* fullVoxPtr = FULL_PTR_FOR_COORD(mapData, wrappedStartPoint);
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                AV::uint32* voxPtr = fullVoxPtr;
                AV::uint32* secondaryVoxPtr = fullSecondaryVoxPtr;
                AV::uint32* tertiaryVoxPtr = fullTertiaryVoxPtr;
                fullSecondaryVoxPtr++;
                fullTertiaryVoxPtr++;
                fullVoxPtr++;
                AV::uint8 altitude = *voxPtr & 0xFF;
                RegionId regionId = ((*secondaryVoxPtr) >> 8) & 0xFF;
                if(regionId == REGION_ID_WATER){
                    continue;
                }

                const Biome& b = Biome::getBiomeForId(regionData[regionId].type);

                Biome::FinalVoxChangeFunction func = b.getFinalVoxFunction();
                assert(func != 0);

                (*func)(mapData, fullVoxPtr, fullSecondaryVoxPtr, fullTertiaryVoxPtr, x, y);
            }
        }
    }

}
