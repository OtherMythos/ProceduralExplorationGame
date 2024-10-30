#include "PerformFloodFillMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <stack>
#include <cassert>
#include <iostream>
#include <set>

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
    typedef std::pair<WorldPoint, WorldPoint> FloodFillPoint;
    template<typename T, typename C>
    bool floodFill_(std::stack<FloodFillPoint>& points, int x, int y, AV::uint32 width, AV::uint32 height, T comparisonFunction, C readFunction, std::vector<RegionId>* vals, ExplorationMapData* mapData, AV::uint32 currentIdx, FloodFillEntry* floodData){
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;
        size_t idx = x+y*width;
        assert(idx < vals->size());
        if((*vals)[idx] != INVALID_REGION_ID){
            return 0;
        }

        AV::uint8 readVal = readFunction(mapData, x, y);
        if(!comparisonFunction(mapData, readVal)){
            return true;
        }

        if(x == 0 || y == 0 || x == mapData->width-1 || y == mapData->height-1){
            floodData->nextToWorldEdge = true;
        }

        (*vals)[idx] = currentIdx;
        floodData->total++;
        WorldPoint wrappedPos = WRAP_WORLD_POINT(x, y);
        floodData->coords.push_back(wrappedPos);
        AV::uint8 isEdge = 0;
        points.push({WRAP_WORLD_POINT(x-1, y), wrappedPos});
        points.push({WRAP_WORLD_POINT(x+1, y), wrappedPos});
        points.push({WRAP_WORLD_POINT(x, y-1), wrappedPos});
        points.push({WRAP_WORLD_POINT(x, y+1), wrappedPos});

        return false;
    }
    template<typename T, typename C, int S>
    void inline floodFill(T comparisonFunction, C readFunction, ExplorationMapData* mapData, std::vector<FloodFillEntry*>& outData, bool writeToBlob=true){
        std::vector<RegionId> vals;
        vals.resize(mapData->width * mapData->height, INVALID_REGION_ID);
        AV::uint32 currentIdx = 0;

        for(int y = 0; y < mapData->height; y++){
            for(int x = 0; x < mapData->width; x++){
                AV::uint8 altitude = readFunction(mapData, x, y);

                if(comparisonFunction(mapData, altitude)){
                    if(vals[x+y*mapData->width] == INVALID_REGION_ID){
                        std::stack<FloodFillPoint> points;
                        points.push({WRAP_WORLD_POINT(x, y), WRAP_WORLD_POINT(x, y)});
                        //TODO prevent pointers.
                        FloodFillEntry* floodData = new FloodFillEntry();
                        std::set<WorldPoint> edgeCoords;
                        floodData->id = currentIdx;
                        floodData->seedX = x;
                        floodData->seedY = y;
                        floodData->nextToWorldEdge = false;

                        while(!points.empty()){
                            FloodFillPoint pointData = points.top();
                            WorldPoint p = pointData.first;
                            points.pop();
                            WorldCoord xx, yy;
                            READ_WORLD_POINT(p, xx, yy);
                            bool nextToEdge = floodFill_<bool(ExplorationMapData*, AV::uint8),AV::uint8(ExplorationMapData*, AV::uint32, AV::uint32)>
                                (points, xx, yy, mapData->width, mapData->height, comparisonFunction, readFunction, &vals, mapData, currentIdx, floodData);
                            if(nextToEdge){
                                edgeCoords.insert(pointData.second);
                            }
                        }

                        //Write the values to the set initially to ensure each value only appears once.
                        //Then copy them over to the list.
                        for(WorldPoint point : edgeCoords){
                            floodData->edges.reserve(edgeCoords.size());
                            floodData->edges.push_back(point);
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
