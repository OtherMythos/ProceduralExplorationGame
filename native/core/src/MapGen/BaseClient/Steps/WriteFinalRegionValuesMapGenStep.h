#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class WriteFinalRegionValuesMapGenStep : public MapGenStep{
    public:
        WriteFinalRegionValuesMapGenStep();
        ~WriteFinalRegionValuesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
