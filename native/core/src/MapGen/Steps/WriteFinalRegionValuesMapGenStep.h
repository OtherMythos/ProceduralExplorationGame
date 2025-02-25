#pragma once

#include "MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class WriteFinalRegionValuesMapGenStep : public MapGenStep{
    public:
        WriteFinalRegionValuesMapGenStep();
        ~WriteFinalRegionValuesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
