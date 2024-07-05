#include "GenerateNoiseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/Util/Random/PatternHelper.h"
#include "System/Util/Random/PerlinNoise.h"

namespace ProceduralExplorationGameCore{

    GenerateNoiseMapGenStep::GenerateNoiseMapGenStep(){

    }

    GenerateNoiseMapGenStep::~GenerateNoiseMapGenStep(){

    }

    void GenerateNoiseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData){
        //TODO look into separating these into individual jobs.
        //AV::PatternHelper::GenPerlinNoise(mapData->width, mapData->height, static_cast<float*>(mapData->voxelBuffer), 0.02, 4);

        int div = 4;
        int divHeight = input->height / div;
        for(int i = 0; i < 4; i++){
            GenerateNoiseMapGenJob job;
            //TODO separate the jobs out and designate to worker threads.
            job.processJob(mapData, 0, i * divHeight, input->width, i * divHeight + divHeight);
        }
    }



    GenerateNoiseMapGenJob::GenerateNoiseMapGenJob(){

    }

    GenerateNoiseMapGenJob::~GenerateNoiseMapGenJob(){

    }

    void GenerateNoiseMapGenJob::processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb){
        float* voxPtr = static_cast<float*>(mapData->voxelBuffer);
        for(AV::uint32 y = ya; y < yb; y++){
            for(AV::uint32 x = xa; x < xb; x++){
                *(voxPtr + (x+y*mapData->width)) = AV::Perlin::perlin2d(x, y, 0.02, 4);
            }
        }

        float* secondaryPtr = static_cast<float*>(mapData->secondaryVoxelBuffer);
        for(AV::uint32 y = ya; y < yb; y++){
            for(AV::uint32 x = xa; x < xb; x++){
                *(secondaryPtr + (x+y*mapData->width)) = AV::Perlin::perlin2d(x, y, 0.05, 4);
            }
        }

        float* blueNoisePtr = static_cast<float*>(mapData->blueNoiseBuffer);
        for(AV::uint32 y = ya; y < yb; y++){
            for(AV::uint32 x = xa; x < xb; x++){
                *(blueNoisePtr + (x+y*mapData->width)) = AV::Perlin::perlin2d(x, y, 0.5, 1);
            }
        }
    }
}
