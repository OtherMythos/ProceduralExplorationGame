#include "ReduceNoiseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    ReduceNoiseMapGenStep::ReduceNoiseMapGenStep() : MapGenStep("Reduce Noise"){

    }

    ReduceNoiseMapGenStep::~ReduceNoiseMapGenStep(){

    }

    ReduceNoiseMapGenJob::ReduceNoiseMapGenJob(){

    }

    ReduceNoiseMapGenJob::~ReduceNoiseMapGenJob(){

    }

    void ReduceNoiseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = input->uint32("width");
        const AV::uint32 height = input->uint32("height");

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            ReduceNoiseMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight, workspace->additionLayer);
        }
    }


    void ReduceNoiseMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb, const std::vector<float>& additionVals){
        const AV::uint32 width = mapData->width;

        {
            float* voxPtr = static_cast<float*>(mapData->voidPtr("voxelBuffer"));
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    float* target = (voxPtr + (x+y*width));

                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(*target * (float)0xFF);
                }
            }
        }

        {
            float* voxPtr = static_cast<float*>(mapData->voidPtr("secondaryVoxelBuffer"));
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    float* target = (voxPtr + (x+y*width));
                    float val = (*target * (float)0xFF);
                    assert(val <= (float)0xFF);
                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(val);
                }
            }
        }

    }
}
