#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class PerformPreFloodFillMapGenStep : public MapGenStep{
    public:
        PerformPreFloodFillMapGenStep();
        ~PerformPreFloodFillMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PerformPreFloodFillMapGenJob{
    public:
        PerformPreFloodFillMapGenJob();
        ~PerformPreFloodFillMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
