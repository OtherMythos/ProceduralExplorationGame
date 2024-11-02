#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class DetermineRiversMapGenStep : public MapGenStep{
    public:
        DetermineRiversMapGenStep();
        ~DetermineRiversMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
