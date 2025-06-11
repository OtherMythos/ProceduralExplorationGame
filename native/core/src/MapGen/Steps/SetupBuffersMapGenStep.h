#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    class ExplorationMapData;

    class SetupBuffersMapGenStep : public MapGenStep{
    public:
        SetupBuffersMapGenStep();
        ~SetupBuffersMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
