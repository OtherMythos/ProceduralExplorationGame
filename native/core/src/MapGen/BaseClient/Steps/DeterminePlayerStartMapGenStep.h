#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class DeterminePlayerStartMapGenStep : public MapGenStep{
    public:
        DeterminePlayerStartMapGenStep();
        ~DeterminePlayerStartMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
