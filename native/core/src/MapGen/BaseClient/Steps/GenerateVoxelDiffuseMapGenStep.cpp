#include "GenerateVoxelDiffuseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "PerlinNoise.h"

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

        return true;
    }

}
