#pragma once

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <queue>

namespace ProceduralExplorationGameCore{

    template <typename T>
    static void _calculateMapGenItemQueue(ExplorationMapData* mapData, const T& d, std::queue<std::pair<WorldPoint, int>>& queue, std::vector<AV::uint8>& distances){
        // Mark all region voxels as valid (distance will be calculated)
        for(WorldPoint p : d.coords){
            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);
            int index = x + y * mapData->width; // Assuming 2D coordinates
            distances[index] = 254; // Mark as region voxel but not yet processed
        }

        // Add edge voxels to queue with distance 0
        for(WorldPoint edgePoint : d.edges){
            WorldCoord x, y;
            READ_WORLD_POINT(edgePoint, x, y);
            int index = x + y * mapData->width;
            distances[index] = 0; // Edge distance is 0
            queue.push(std::make_pair(edgePoint, 0));
        }
    }

    static void _calculateDistance(ExplorationMapData* mapData, std::queue<std::pair<WorldPoint, int>>& queue, std::vector<AV::uint8>& distances){
        while(!queue.empty()){
            auto current = queue.front();
            queue.pop();

            WorldPoint currentPoint = current.first;
            int currentDistance = current.second;

            WorldCoord x, y;
            READ_WORLD_POINT(currentPoint, x, y);
            // Check 4-connected neighbors (Manhattan distance)
            std::vector<WorldPoint> neighbors = {
                WRAP_WORLD_POINT(x + 1, y),
                WRAP_WORLD_POINT(x - 1, y),
                WRAP_WORLD_POINT(x, y + 1),
                WRAP_WORLD_POINT(x, y - 1)
            };

            for(const WorldPoint& neighbor : neighbors){
                // Check bounds
                WorldCoord nX, nY;
                READ_WORLD_POINT(neighbor, nX, nY);
                if(nX >= mapData->width || nY >= mapData->height){
                    continue;
                }

                int neighborIndex = nX + nY * mapData->width;

                // If this neighbor is a region voxel that hasn't been processed yet
                if(distances[neighborIndex] == 254){
                    int newDistance = currentDistance + 1;

                    // Clamp to max uint8 value
                    if(newDistance > 253) newDistance = 253;

                    distances[neighborIndex] = static_cast<AV::uint8>(newDistance);

                    queue.push(std::make_pair(neighbor, newDistance));
                }
            }
        }
    }

    static void calculateRegionDistance(ExplorationMapData* mapData, std::vector<AV::uint8>& distances){

        std::queue<std::pair<WorldPoint, int>> queue;

        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        for(const RegionData& d : regionData){
            _calculateMapGenItemQueue<RegionData>(mapData, d, queue, distances);
        }

        _calculateDistance(mapData, queue, distances);
    }

    static void calculateWaterDistance(ExplorationMapData* mapData, std::vector<AV::uint8>& distances){

        std::queue<std::pair<WorldPoint, int>> queue;

        //const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));
        const std::vector<FloodFillEntry*>& waterData = (*mapData->ptr<std::vector<FloodFillEntry*>>("waterData"));

        for(const FloodFillEntry* d : waterData){
            _calculateMapGenItemQueue<FloodFillEntry>(mapData, *d, queue, distances);
        }

        _calculateDistance(mapData, queue, distances);
    }

}
