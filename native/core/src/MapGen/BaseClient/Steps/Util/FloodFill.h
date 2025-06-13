#pragma once

#include <stack>
#include <cassert>
#include <set>

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    typedef std::pair<WorldPoint, WorldPoint> FloodFillPoint;
    template<typename T, typename TT, typename C>
    bool floodFill_(std::stack<FloodFillPoint>& points, int x, int y, AV::uint32 width, AV::uint32 height, T comparisonFunction, C readFunction, std::vector<RegionId>* vals, ExplorationMapData* mapData, AV::uint32 currentIdx, FloodFillEntry* floodData){
        if(x < 0 || y < 0 || x >= width || y >= height) return 0;
        size_t idx = x+y*width;
        assert(idx < vals->size());
        if((*vals)[idx] != INVALID_REGION_ID){
            return 0;
        }

        TT readVal = readFunction(mapData, x, y);
        if(!comparisonFunction(mapData, readVal)){
            return true;
        }

        if(x == 0 || y == 0 || x == width-1 || y == height-1){
            floodData->nextToWorldEdge = true;
        }

        assert(currentIdx < INVALID_REGION_ID);
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
    template<typename T, typename C, typename TT, int S>
    void inline _floodFillForPos(T comparisonFunction, C readFunction, int x, int y, ExplorationMapData* mapData, AV::uint32& currentIdx, std::vector<RegionId>& vals, std::vector<FloodFillEntry*>& outData, AV::uint32 width, AV::uint32 height, bool writeToBlob=true){
        TT altitude = readFunction(mapData, x, y);

        if(comparisonFunction(mapData, altitude)){
            if(vals[x+y*width] == INVALID_REGION_ID){
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
                    bool nextToEdge = floodFill_<T, TT, C>
                        (points, xx, yy, width, height, comparisonFunction, readFunction, &vals, mapData, currentIdx, floodData);
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
    template<typename T, typename C, int S>
    void inline floodFill(T comparisonFunction, C readFunction, ExplorationMapData* mapData, std::vector<FloodFillEntry*>& outData, bool writeToBlob=true){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        std::vector<RegionId> vals;
        vals.resize(width * height, INVALID_REGION_ID);
        AV::uint32 currentIdx = 0;

        for(int y = 0; y < height; y++){
            for(int x = 0; x < width; x++){
                _floodFillForPos<T, C, AV::uint8, S>
                    (comparisonFunction, readFunction, x, y, mapData, currentIdx, vals, outData, width, height, writeToBlob);
                //currentIdx++;
            }
        }

        if(writeToBlob){
            assert(mapData->sizeType("voxelBufferSize") / 4 == vals.size());
            AV::uint32* voxPtr = reinterpret_cast<AV::uint32*>(mapData->voidPtr("voxelBuffer"));
            for(size_t i = 0; i < vals.size(); i++){
                AV::uint8* subPtr = reinterpret_cast<AV::uint8*>(voxPtr);
                *(subPtr+S) = (vals[i] & 0xFF);
                voxPtr++;
            }
        }
    }


};
