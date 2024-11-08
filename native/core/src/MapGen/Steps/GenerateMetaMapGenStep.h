#pragma once

#include "MapGenStep.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class GenerateMetaMapGenStep : public MapGenStep{
    public:
        GenerateMetaMapGenStep();
        ~GenerateMetaMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
