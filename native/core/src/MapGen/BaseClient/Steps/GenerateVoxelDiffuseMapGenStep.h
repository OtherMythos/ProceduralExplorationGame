#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateVoxelDiffuseMapGenStep : public MapGenStep{
    public:
        GenerateVoxelDiffuseMapGenStep();
        ~GenerateVoxelDiffuseMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
