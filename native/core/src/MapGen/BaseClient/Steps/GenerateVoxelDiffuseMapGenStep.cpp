#include "GenerateVoxelDiffuseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "PerlinNoise.h"

#include <queue>
#include <set>

namespace ProceduralExplorationGameCore{

    GenerateVoxelDiffuseMapGenStep::GenerateVoxelDiffuseMapGenStep() : MapGenStep("Generate Voxel Diffuse"){

    }

    GenerateVoxelDiffuseMapGenStep::~GenerateVoxelDiffuseMapGenStep(){

    }

    bool GenerateVoxelDiffuseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        PerlinNoise noiseGen(mapData->uint32("seed"));

        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                //Generate diffuse value using blend of Perlin noise and random noise
                float noiseValue = noiseGen.perlin2d(x, y, 0.1, 2);
                noiseValue = (noiseValue + 1.0f) / 2.0f; //Normalise Perlin to 0-1

                float randomValue = static_cast<float>(mapGenRandomIntMinMax(0, 100)) / 100.0f; //0-1 random

                float blendedValue = noiseValue * 0.8f + randomValue * 0.2f;
                AV::uint8 diffuseValue = static_cast<AV::uint8>(blendedValue * 4.0f);

                //Pack into the lower three bits of byte 0 of secondary voxel buffer
                AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                *metaPtr = diffuseValue & 0x7;
            }
        }

        //Darken ground around placed objects
        std::vector<PlacedItemData>* placedItems = mapData->ptr<std::vector<PlacedItemData>>("placedItems");

        for(const PlacedItemData& item : *placedItems){
            //Determine shadow radius based on item type
            int shadowRadius = 2;
            if(item.type == PlacedItemId::CACTUS){
                shadowRadius = 8;
            }

            int centerX = static_cast<int>(item.originX);
            int centerY = static_cast<int>(item.originY);

            //Draw shadow pattern around object with dithering based on distance
            for(int dy = -shadowRadius; dy <= shadowRadius; dy++){
                for(int dx = -shadowRadius; dx <= shadowRadius; dx++){
                    int vx = centerX + dx;
                    int vy = centerY + dy;

                    //Bounds check
                    if(vx < 0 || vx >= static_cast<int>(width) || vy < 0 || vy >= static_cast<int>(height)) continue;

                    //Calculate distance from object center
                    float distance = sqrtf(static_cast<float>(dx * dx + dy * dy));

                    //Skip the center
                    if(distance < 0.5f) continue;

                    //Calculate falloff based on distance (0 at edge, 1 near center)
                    float falloff = 1.0f - (distance / shadowRadius);

                    //Apply dithering: higher chance of darkening when closer
                    float randomChance = static_cast<float>(mapGenRandomIntMinMax(0, 100)) / 100.0f;
                    if(randomChance > falloff) continue; //Skip this voxel based on dither

                    //Darken the diffuse value (max value is 7, so reduce by 3-5 based on falloff)
                    AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(vx, vy));
                    AV::uint8 currentDiffuse = *metaPtr & 0x7;
                    AV::uint8 darkAmount = static_cast<AV::uint8>(3.0f + falloff * 2.0f); //Darken by 3-5
                    AV::uint8 newDiffuse = currentDiffuse > darkAmount ? currentDiffuse - darkAmount : 0;
                    *metaPtr = newDiffuse & 0x7;
                }
            }
        }

        //Apply random diffuse noise to all path voxels
        std::vector<PathSegment>* pathData = mapData->ptr<std::vector<PathSegment>>("pathData");

        //Collect all unique path points into a set
        std::set<WorldPoint> uniquePathPoints;
        for(const PathSegment& path : *pathData){
            for(const WorldPoint& p : path.pointsExpanded){
                uniquePathPoints.insert(p);
            }
        }

        //Calculate distance from each voxel to the nearest path
        std::vector<AV::uint8> pathDistances(width*height, 255); //255=not calculated

        //BFS from all path points
        std::queue<std::pair<WorldPoint, int>> distanceQueue;

        //Initialize: mark all path points with distance 0
        for(const WorldPoint& p : uniquePathPoints){
            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);

            if(x>=0&&y>=0&&x<static_cast<WorldCoord>(width)&&y<static_cast<WorldCoord>(height)){
                int index=x+y*width;
                pathDistances[index]=0;
                distanceQueue.push({p, 0});
            }
        }

        //BFS to propagate distances
        while(!distanceQueue.empty()){
            auto current=distanceQueue.front();
            distanceQueue.pop();

            WorldPoint currentPoint=current.first;
            int currentDist=current.second;

            WorldCoord x, y;
            READ_WORLD_POINT(currentPoint, x, y);

            //Check 8-connected neighbors (including diagonals)
            for(int dx=-1; dx<=1; dx++){
                for(int dy=-1; dy<=1; dy++){
                    if(dx==0&&dy==0) continue;

                    WorldCoord nx=x+dx;
                    WorldCoord ny=y+dy;

                    //Bounds check
                    if(nx<0||ny<0||nx>=static_cast<WorldCoord>(width)||ny>=static_cast<WorldCoord>(height)){
                        continue;
                    }

                    int neighborIndex=nx+ny*width;

                    //If not yet processed
                    if(pathDistances[neighborIndex]==255){
                        int newDist=currentDist+1;
                        if(newDist>254) newDist=254;

                        pathDistances[neighborIndex]=static_cast<AV::uint8>(newDist);
                        distanceQueue.push({WRAP_WORLD_POINT(nx, ny), newDist});
                    }
                }
            }
        }

        //Apply drop shadow effect based on distance from paths
        for(AV::uint32 y=0; y<height; y++){
            for(AV::uint32 x=0; x<width; x++){
                int index=x+y*width;
                AV::uint8 distFromPath=pathDistances[index];

                //Only apply shadow if voxel is within 4 units of a path
                if(distFromPath==255||distFromPath>2){
                    continue;
                }

                //Calculate shadow intensity: full gradient from 7 (on path) to 0 (4 tiles away)
                float shadowFalloff=(static_cast<float>(distFromPath)/2.0f);
                float shadowValue=(shadowFalloff)*2.0f;
                AV::uint8 shadowAmount=static_cast<AV::uint8>(shadowValue);

                AV::uint8* metaPtr=VOXEL_META_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                *metaPtr=(*metaPtr&0xF8)|(shadowAmount&0x7);
            }
        }

        //Apply random noise to path points themselves
        for(const WorldPoint& p : uniquePathPoints){
            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);

            AV::uint8 randomDiffuse=static_cast<AV::uint8>(mapGenRandomIntMinMax(0, 0x7));

            AV::uint8* metaPtr=VOXEL_META_PTR_FOR_COORD(mapData, p);
            *metaPtr=(*metaPtr&0xF8)|(randomDiffuse&0x7);
        }

        return true;
    }

}
