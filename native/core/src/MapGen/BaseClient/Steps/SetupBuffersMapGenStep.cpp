#include "SetupBuffersMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    SetupBuffersMapGenStep::SetupBuffersMapGenStep() : MapGenStep("Setup Buffers"){

    }

    SetupBuffersMapGenStep::~SetupBuffersMapGenStep(){

    }

    void SetupBuffersMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const size_t NUM_VOX = mapData->width * mapData->height;
        const size_t VOX_BUF_SIZE = (NUM_VOX * sizeof(float));
        const size_t SECONDARY_VOX_BUF_SIZE = (NUM_VOX * sizeof(float));
        const size_t BLUE_NOISE_BUF_SIZE = (NUM_VOX * sizeof(float));

        const size_t BUF_SIZE = VOX_BUF_SIZE + SECONDARY_VOX_BUF_SIZE + BLUE_NOISE_BUF_SIZE;

        void* start = malloc(BUF_SIZE);
        AV::uint8* startPtr = reinterpret_cast<AV::uint8*>(start);

        mapData->voxelBuffer = reinterpret_cast<void*>(startPtr);
        mapData->secondaryVoxelBuffer = reinterpret_cast<void*>(startPtr + VOX_BUF_SIZE);
        mapData->blueNoiseBuffer = reinterpret_cast<void*>(startPtr + (VOX_BUF_SIZE + SECONDARY_VOX_BUF_SIZE));

        //mapData->voxelBufferSize = VOX_BUF_SIZE;
        //mapData->secondaryVoxelBufferSize = SECONDARY_VOX_BUF_SIZE;
        //mapData->blueNoiseBufferSize = BLUE_NOISE_BUF_SIZE;

        mapData->voidPtr("voxelBuffer", reinterpret_cast<void*>(startPtr));
        mapData->voidPtr("secondaryVoxelBuffer", reinterpret_cast<void*>(startPtr + VOX_BUF_SIZE));
        mapData->voidPtr("blueNoiseBuffer", startPtr + (VOX_BUF_SIZE + SECONDARY_VOX_BUF_SIZE));

        mapData->sizeType("voxelBufferSize", VOX_BUF_SIZE);
        mapData->sizeType("secondaryVoxelBufferSize", SECONDARY_VOX_BUF_SIZE);
        mapData->sizeType("blueNoiseBufferSize", BLUE_NOISE_BUF_SIZE);
    }

}
