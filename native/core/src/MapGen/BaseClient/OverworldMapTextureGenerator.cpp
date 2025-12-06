#include "OverworldMapTextureGenerator.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/BaseClient/Steps/Util/MapGenDistance.h"

#include <cassert>
#include <cstring>
#include <queue>

namespace ProceduralExplorationGameCore{

    OverworldMapTextureGenerator::OverworldMapTextureGenerator(){

    }

    OverworldMapTextureGenerator::~OverworldMapTextureGenerator(){

    }

    static void _writeToBuffer(float** buf, float r, float g, float b, float a=255.0){
        *((*buf)) = r / 255;
        (*buf)++;
        *((*buf)) = g / 255;
        (*buf)++;
        *((*buf)) = b / 255;
        (*buf)++;
        *((*buf)) = a / 255;
    }

    void OverworldMapTextureGenerator::generateWaterTextureBuffers(ExplorationMapData* mapData){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        size_t bufSize = width * height * sizeof(float) * 4;
        float* buffer = static_cast<float*>(malloc(bufSize));
        memset(buffer, 0, bufSize);
        float* bufferMask = static_cast<float*>(malloc(bufSize));
        memset(bufferMask, 0, bufSize);

        const AV::uint32 seaLevel = mapData->seaLevel;

        int seaLevelCutoff = 15;
        int seaLevelCutoffSecond = 8;

        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, p);
                const AV::uint8* distPtr = REGION_DISTANCE_PTR_FOR_COORD(mapData, p);

                int reverseWidth = height - y - 1;
                if(reverseWidth >= (int)height) continue;
                float* b = ((buffer) + ((x + reverseWidth * width) * 4));
                float* bMask = ((bufferMask) + ((x + reverseWidth * width) * 4));

                //For overworld, altitude determines if it's land or water
                //Once determined to be water, use distance to land to determine pixel type
                if(*altitude >= seaLevel){
                    //This is land, just write transparent
                    _writeToBuffer(&b, 143, 189, 207);
                }else{
                    //This is water - use distance to determine which type of water
                    if(*distPtr < 4){
                        //Close to land - draw foam
                        _writeToBuffer(&b, 143, 189, 207);
                    }else if(*distPtr < seaLevelCutoff){
                        //Medium distance from land
                        _writeToBuffer(&b, 113, 159, 177);
                    }else{
                        //Far from land - deep water
                        _writeToBuffer(&b, 0, 102, 255);
                    }
                }

                //Mask generation - only for water pixels
                if(*altitude < seaLevel){
                    //Use distance to determine mask intensity
                    if(*distPtr < 4){
                        //Close to land
                        _writeToBuffer(&bMask, 0, 0, 0, 0);
                    }else if(*distPtr < seaLevelCutoff){
                        //Medium distance
                        _writeToBuffer(&bMask, 20, 0, 0, 0);
                    }else{
                        //Far from land
                        _writeToBuffer(&bMask, 255, 0, 0, 0);
                    }
                }
            }
        }

        mapData->voidPtr("waterTextureBuffer", buffer);
        mapData->voidPtr("waterTextureBufferMask", bufferMask);
    }

    void OverworldMapTextureGenerator::generateTexture(ExplorationMapData* mapData){
        //First, calculate distances from water to land
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        //Initialise distance array
        std::vector<AV::uint8> distances;
        distances.resize(width * height, 255);

        //Mark all land voxels (altitude >= seaLevel) with 254 to indicate they need processing
        const AV::uint32 seaLevel = mapData->seaLevel;
        std::queue<std::pair<WorldPoint, int>> queue;

        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, p);

                if(*altitude >= seaLevel){
                    //This is land
                    int index = x + y * width;
                    distances[index] = 254;
                }
            }
        }

        //Add water voxels adjacent to land as edges with distance 0
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, p);

                if(*altitude < seaLevel){
                    //This is water, check if adjacent to land
                    bool adjacentToLand = false;
                    for(int dy = -1; dy <= 1; dy++){
                        for(int dx = -1; dx <= 1; dx++){
                            if(dx == 0 && dy == 0) continue;
                            int nx = x + dx;
                            int ny = y + dy;
                            if(nx < 0 || nx >= (int)width || ny < 0 || ny >= (int)height) continue;

                            WorldPoint np = WRAP_WORLD_POINT(nx, ny);
                            const AV::uint8* neighbourAltitude = VOX_PTR_FOR_COORD_CONST(mapData, np);
                            if(*neighbourAltitude >= seaLevel){
                                adjacentToLand = true;
                                break;
                            }
                        }
                        if(adjacentToLand) break;
                    }

                    if(adjacentToLand){
                        int index = x + y * width;
                        distances[index] = 0;
                        queue.push(std::make_pair(p, 0));
                    }
                }
            }
        }

        //BFS to calculate distances
        while(!queue.empty()){
            auto current = queue.front();
            queue.pop();

            WorldPoint currentPoint = current.first;
            int currentDistance = current.second;

            WorldCoord x, y;
            READ_WORLD_POINT(currentPoint, x, y);
            int index = x + y * width;

            //Check 4-connected neighbours
            std::vector<WorldPoint> neighbours = {
                WRAP_WORLD_POINT(x + 1, y),
                WRAP_WORLD_POINT(x - 1, y),
                WRAP_WORLD_POINT(x, y + 1),
                WRAP_WORLD_POINT(x, y - 1)
            };

            for(const WorldPoint& neighbour : neighbours){
                WorldCoord nX, nY;
                READ_WORLD_POINT(neighbour, nX, nY);
                if(nX >= width || nY >= height) continue;

                int neighbourIndex = nX + nY * width;

                if(distances[neighbourIndex] == 255){
                    //Unvisited water voxel
                    int newDistance = currentDistance + 1;
                    if(newDistance > 253) newDistance = 253;

                    distances[neighbourIndex] = static_cast<AV::uint8>(newDistance);
                    queue.push(std::make_pair(neighbour, newDistance));
                }
            }
        }

        //Write distances to map data
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                AV::uint8* distPtr = REGION_DISTANCE_PTR_FOR_COORD(mapData, p);
                *distPtr = distances[x + y * width];
            }
        }

        //Generate the water texture using the calculated distances
        generateWaterTextureBuffers(mapData);
    }

}
