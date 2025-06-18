#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class MergeIsolatedRegionsMapGenStep : public MapGenStep{
    public:
        MergeIsolatedRegionsMapGenStep();
        ~MergeIsolatedRegionsMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
