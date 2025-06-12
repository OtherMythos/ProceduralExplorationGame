#include "PerformFinalFloodFillMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "Util/FloodFill.h"

namespace ProceduralExplorationGameCore{

    PerformFinalFloodFillMapGenStep::PerformFinalFloodFillMapGenStep() : MapGenStep("Perform Final Flood Fill"){

    }

    PerformFinalFloodFillMapGenStep::~PerformFinalFloodFillMapGenStep(){

    }

    void PerformFinalFloodFillMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        //TODO in future one thread gets land and another water.
        PerformFinalFloodFillMapGenJob floodFillWater;
        floodFillWater.processJob(mapData);
    }



    PerformFinalFloodFillMapGenJob::PerformFinalFloodFillMapGenJob(){

    }

    PerformFinalFloodFillMapGenJob::~PerformFinalFloodFillMapGenJob(){

    }

    AV::uint32 seaLevel = 0;
    AV::uint32 mapWidth = 0;
    void* voxelBuffer = 0;
    inline bool PerformFinalFloodFillMapGenJob::comparisonFuncLand(ExplorationMapData* mapData, AV::uint8 val){
        return val >= seaLevel;
    }
    inline AV::uint8 PerformFinalFloodFillMapGenJob::readFuncAltitude(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y){
        return static_cast<AV::uint8>(*(reinterpret_cast<AV::uint32*>(voxelBuffer) + x + y * mapWidth) & 0xFF);
    }
    inline bool PerformFinalFloodFillMapGenJob::comparisonFuncWater(ExplorationMapData* mapData, AV::uint8 val){
        return val < seaLevel;
    }
    void PerformFinalFloodFillMapGenJob::processJob(ExplorationMapData* mapData){
        seaLevel = mapData->uint32("seaLevel");
        mapWidth = mapData->width;
        voxelBuffer = mapData->voidPtr("voxelBuffer");

        std::vector<FloodFillEntry*>* e = new std::vector<FloodFillEntry*>();
        floodFill<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32), 2>(comparisonFuncWater, readFuncAltitude, mapData, *e);
        mapData->voidPtr("waterData", e);
        //mapData->waterData = std::move(waterResult);

        std::vector<FloodFillEntry*> landResult;
        e = new std::vector<FloodFillEntry*>();
        floodFill<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32), 3>(comparisonFuncLand, readFuncAltitude, mapData, *e);
        mapData->voidPtr("landData", e);

        //Sanity checks, should get compiled out in release builds.
        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
                const AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                const AV::uint8* landGroup = LAND_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));

                if(*waterGroup == INVALID_WATER_ID){
                    assert(*landGroup != INVALID_LAND_ID);
                }
                if(*landGroup == INVALID_LAND_ID){
                    assert(*waterGroup != INVALID_WATER_ID);
                }
            }
        }
    }
}
