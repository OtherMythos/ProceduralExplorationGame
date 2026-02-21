#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class DetermineBeachVoxelsMapGenStep : public MapGenStep{
    public:
        DetermineBeachVoxelsMapGenStep();
        ~DetermineBeachVoxelsMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
