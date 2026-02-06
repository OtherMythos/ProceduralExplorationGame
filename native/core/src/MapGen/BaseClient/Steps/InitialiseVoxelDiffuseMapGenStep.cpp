#include "InitialiseVoxelDiffuseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    InitialiseVoxelDiffuseMapGenStep::InitialiseVoxelDiffuseMapGenStep() : MapGenStep("Initialise Voxel Diffuse"){

    }

    InitialiseVoxelDiffuseMapGenStep::~InitialiseVoxelDiffuseMapGenStep(){

    }

    bool InitialiseVoxelDiffuseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                VOXEL_META_SET_DIFFUSE(mapData, WRAP_WORLD_POINT(x, y), 7);
            }
        }

        return true;
    }

}
