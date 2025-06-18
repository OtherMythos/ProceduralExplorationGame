#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class DetermineRegionTypesMapGenStep : public MapGenStep{
    public:
        DetermineRegionTypesMapGenStep();
        ~DetermineRegionTypesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
