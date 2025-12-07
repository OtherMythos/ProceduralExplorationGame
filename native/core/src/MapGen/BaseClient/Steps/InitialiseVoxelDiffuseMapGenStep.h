#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    class InitialiseVoxelDiffuseMapGenStep : public MapGenStep{
    public:
        InitialiseVoxelDiffuseMapGenStep();
        ~InitialiseVoxelDiffuseMapGenStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);
    };

}
