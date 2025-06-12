#include "DetermineEdgesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "GameplayConstants.h"

#include <cassert>

namespace ProceduralExplorationGameCore{

    DetermineEdgesMapGenStep::DetermineEdgesMapGenStep() : MapGenStep("Determine Edges"){

    }

    DetermineEdgesMapGenStep::~DetermineEdgesMapGenStep(){

    }

    void _outlineEdge(std::vector<FloodFillEntry*>& entries, const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;

        for(FloodFillEntry* d : entries){
            for(WorldPoint i : d->edges){
                WorldCoord x, y;
                READ_WORLD_POINT(i, x, y);
                size_t size = x + y * width;
                AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voidPtr("voxelBuffer"));
                voxPtr += size;
                *voxPtr |= (1 << 15);
            }
        }
    }

    void DetermineEdgesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        _outlineEdge(mapData->landData, input, mapData, workspace);
        _outlineEdge(mapData->waterData, input, mapData, workspace);
    }

}
