#include "GenerateNoiseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/Util/Random/PatternHelper.h"
//#include "System/Util/Random/PerlinNoise.h"
#include "PerlinNoise.h"

namespace ProceduralExplorationGameCore{

    GenerateNoiseMapGenStep::GenerateNoiseMapGenStep() : MapGenStep("Generate Noise"){

    }

    GenerateNoiseMapGenStep::~GenerateNoiseMapGenStep(){

    }

    void GenerateNoiseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            GenerateNoiseMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight);
        }
    }



    GenerateNoiseMapGenJob::GenerateNoiseMapGenJob(){

    }

    GenerateNoiseMapGenJob::~GenerateNoiseMapGenJob(){

    }

    void GenerateNoiseMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){

        const AV::uint32 width = mapData->width;

        {
            PerlinNoise noiseGen(mapData->uint32("seed"));

            float* voxPtr = static_cast<float*>(mapData->voidPtr("voxelBuffer"));
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    *(voxPtr + (x+y*width)) = noiseGen.perlin2d(x, y, 0.02, 4);
                }
            }
        }

        {
            PerlinNoise noiseGen(mapData->uint32("moistureSeed"));

            float* secondaryPtr = static_cast<float*>(mapData->voidPtr("secondaryVoxelBuffer"));
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    *(secondaryPtr + (x+y*width)) = noiseGen.perlin2d(x, y, 0.05, 4);
                }
            }
        }

        {
            PerlinNoise noiseGen(mapData->uint32("variationSeed"));

            float* blueNoisePtr = static_cast<float*>(mapData->voidPtr("blueNoiseBuffer"));
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    *(blueNoisePtr + (x+y*width)) = noiseGen.perlin2d(x, y, 0.5, 1);
                }
            }
        }

    }
}
