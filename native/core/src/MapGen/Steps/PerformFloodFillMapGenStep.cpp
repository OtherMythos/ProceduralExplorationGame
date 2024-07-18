#include "PerformFloodFillMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <stack>
#include <cassert>
#include <iostream>

namespace ProceduralExplorationGameCore{

    PerformFloodFillMapGenStep::PerformFloodFillMapGenStep(){

    }

    PerformFloodFillMapGenStep::~PerformFloodFillMapGenStep(){

    }

    void PerformFloodFillMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        //TODO in future one thread gets land and another water.
        PerformFloodFillMapGenJob floodFillWater;
        floodFillWater.processJob(mapData);
    }



    PerformFloodFillMapGenJob::PerformFloodFillMapGenJob(){

    }

    PerformFloodFillMapGenJob::~PerformFloodFillMapGenJob(){

    }

    inline bool comparisonFuncLand(ExplorationMapData* mapData, AV::uint8 val){
        return val >= mapData->seaLevel;
    }
    inline AV::uint8 readFuncAltitude(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y){
        return static_cast<AV::uint8>(*(reinterpret_cast<AV::uint32*>(mapData->voxelBuffer) + x + y * mapData->height) & 0xFF);
    }
    inline bool comparisonFuncWater(ExplorationMapData* mapData, AV::uint8 val){
        return val < mapData->seaLevel;
    }
    template<typename T, typename C>
    AV::uint8 floodFill_(std::stack<WorldPoint>& points, int x, int y, AV::uint32 width, AV::uint32 height, T comparisonFunction, C readFunction, std::vector<RegionId>* vals, ExplorationMapData* mapData, AV::uint32 currentIdx, FloodFillEntry* floodData){
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;
        size_t idx = x+y*width;
        assert(idx < vals->size());
        if((*vals)[idx] != 0xFF){
            return 0;
        }

        AV::uint8 readVal = readFunction(mapData, x, y);
        if(!comparisonFunction(mapData, readVal)){
            return 1;
        }

        if(x == 0 || y == 0 || x == mapData->width-1 || y == mapData->height-1){
            floodData->nextToWorldEdge = true;
        }

        (*vals)[idx] = currentIdx;
        floodData->total++;
        WorldPoint wrappedPos = WRAP_WORLD_POINT(x, y);
        floodData->coords.push_back(wrappedPos);
        AV::uint8 isEdge = 0;
        points.push(WRAP_WORLD_POINT(x-1, y));
        points.push(WRAP_WORLD_POINT(x+1, y));
        points.push(WRAP_WORLD_POINT(x, y-1));
        points.push(WRAP_WORLD_POINT(x, y+1));

        //TODO Properly add the edge logic.
        /*
        if(isEdge){
            floodData->edges.push_back(wrappedPos);
        }
         */

        return 0;
    }
    template<typename T, typename C, int S>
    void inline floodFill(T comparisonFunction, C readFunction, ExplorationMapData* mapData, std::vector<FloodFillEntry*>& outData, bool writeToBlob=true){
        std::vector<RegionId> vals;
        //TODO add a constant for invalid region entry.
        vals.resize(mapData->width * mapData->height, 0xFF);
        AV::uint32 currentIdx = 0;

        for(int y = 0; y < mapData->height; y++){
            for(int x = 0; x < mapData->width; x++){
                AV::uint8 altitude = readFunction(mapData, x, y);

                if(comparisonFunction(mapData, altitude)){
                    if(vals[x+y*mapData->width] == 0xFF){
                        std::stack<WorldPoint> points;
                        points.push(WRAP_WORLD_POINT(x, y));
                        //TODO prevent pointers.
                        FloodFillEntry* floodData = new FloodFillEntry();
                        floodData->id = currentIdx;
                        floodData->seedX = x;
                        floodData->seedY = y;
                        floodData->nextToWorldEdge = false;

                        while(!points.empty()){
                            WorldPoint p = points.top();
                            points.pop();
                            WorldCoord xx, yy;
                            READ_WORLD_POINT(p, xx, yy);
                            floodFill_<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32)>
                                (points, xx, yy, mapData->width, mapData->height, comparisonFunction, readFunction, &vals, mapData, currentIdx, floodData);
                        }

                        //Designate this as a newly found region.
                        outData.push_back(floodData);
                        currentIdx++;
                    }
                }
            }
        }

        if(writeToBlob){
            assert(mapData->voxelBufferSize / 4 == vals.size());
            AV::uint32* voxPtr = reinterpret_cast<AV::uint32*>(mapData->voxelBuffer);
            for(size_t i = 0; i < vals.size(); i++){
                AV::uint8* subPtr = reinterpret_cast<AV::uint8*>(voxPtr);
                *(subPtr+S) = (vals[i] & 0xFF);
                voxPtr++;
            }
        }
    }

    void PerformFloodFillMapGenJob::processJob(ExplorationMapData* mapData){
        std::vector<FloodFillEntry*> waterResult;
        floodFill<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32), 2>(comparisonFuncWater, readFuncAltitude, mapData, waterResult);
        mapData->waterData = std::move(waterResult);

        std::vector<FloodFillEntry*> landResult;
        floodFill<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32), 3>(comparisonFuncLand, readFuncAltitude, mapData, landResult);
        mapData->landData = std::move(landResult);

        //Sanity checks, should get compiled out in release builds.
        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
                const AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                const AV::uint8* landGroup = LAND_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));

                if(*waterGroup == 0xFF){
                    assert(*landGroup != 0xFF);
                }
                else if(*landGroup == 0xFF){
                    assert(*waterGroup != 0xFF);
                }
            }
        }
    }
}
