#include "CalculateRegionDistanceMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <queue>

namespace ProceduralExplorationGameCore{

    CalculateRegionDistanceMapGenStep::CalculateRegionDistanceMapGenStep() : MapGenStep("Calculate Region Edges"){

    }

    CalculateRegionDistanceMapGenStep::~CalculateRegionDistanceMapGenStep(){

    }

    void CalculateRegionDistanceMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        CalculateRegionDistanceMapGenJob job;
        job.processJob(mapData, workspace);
    }



    CalculateRegionDistanceMapGenJob::CalculateRegionDistanceMapGenJob(){

    }

    CalculateRegionDistanceMapGenJob::~CalculateRegionDistanceMapGenJob(){

    }

    void CalculateRegionDistanceMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<AV::uint8> distances;
        distances.resize(mapData->width * mapData->height, 255); // 255 = max distance/unvisited
        std::queue<std::pair<WorldPoint, int>> queue; // pair of coordinate and distance

        const std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        // First pass: Initialize all region voxels as unvisited (but valid)
        // and seed the queue with edge voxels at distance 0
        for(const RegionData& d : regionData){
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

        // BFS to calculate distances
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

        //Write the distance to the final buffer.
        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
                AV::uint8 dist = distances[x + y * mapData->width];
                AV::uint8* distPtr = REGION_DISTANCE_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                if(dist >= 254){
                    *distPtr = 0xFF;
                }else{
                    *distPtr = dist;
                }
            }
        }
    }
}
