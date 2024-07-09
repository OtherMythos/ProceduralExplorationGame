#include "ReduceNoiseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    ReduceNoiseMapGenStep::ReduceNoiseMapGenStep(){

    }

    ReduceNoiseMapGenStep::~ReduceNoiseMapGenStep(){

    }

    void ReduceNoiseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        int div = 4;
        int divHeight = input->height / div;
        for(int i = 0; i < 4; i++){
            ReduceNoiseMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, input->width, i * divHeight + divHeight);
        }
    }



    ReduceNoiseMapGenJob::ReduceNoiseMapGenJob(){

    }

    ReduceNoiseMapGenJob::~ReduceNoiseMapGenJob(){

    }

    inline float getHeightForPoint(float input, float x, float y){
        static const float ORIGIN = 0.5;
        float centreOffset = (sqrt(pow(ORIGIN - x, 2) + pow(ORIGIN - y, 2)) + 0.1);
        float curvedOffset = 1 - pow(2, -10 * centreOffset*1.8);

        float val = (1.0f-centreOffset) * input;

        return val;
    }
    void ReduceNoiseMapGenJob::processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb){

        {
            float* voxPtr = static_cast<float*>(mapData->voxelBuffer);
            for(AV::uint32 y = ya; y < yb; y++){
                float yVal = (float)y / (float)mapData->height;
                for(AV::uint32 x = xa; x < xb; x++){
                    float xVal = (float)x / (float)mapData->width;
                    float* target = (voxPtr + (x+y*mapData->width));

                    float heightForPoint = getHeightForPoint(*target, xVal, yVal);
                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(heightForPoint * (float)0xFF);
                }
            }
        }

        {
            float* voxPtr = static_cast<float*>(mapData->secondaryVoxelBuffer);
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    float* target = (voxPtr + (x+y*mapData->width));
                    float val = (*target * (float)0xFF);
                    assert(val <= (float)0xFF);
                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(val);
                }
            }
        }

    }
}
