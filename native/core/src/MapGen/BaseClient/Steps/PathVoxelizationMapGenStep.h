#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    class PathVoxelizationMapGenStep : public MapGenStep{
    public:
        PathVoxelizationMapGenStep();
        virtual ~PathVoxelizationMapGenStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);
    };
}
