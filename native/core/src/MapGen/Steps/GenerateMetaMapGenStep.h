#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateMetaMapGenStep : public MapGenStep{
    public:
        GenerateMetaMapGenStep();
        ~GenerateMetaMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
