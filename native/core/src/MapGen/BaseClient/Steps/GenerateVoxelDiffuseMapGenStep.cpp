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

        return true;
    }

}
