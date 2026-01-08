#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateRegionConcavityMapGenStep : public MapGenStep{
    public:
        CalculateRegionConcavityMapGenStep();
        ~CalculateRegionConcavityMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
