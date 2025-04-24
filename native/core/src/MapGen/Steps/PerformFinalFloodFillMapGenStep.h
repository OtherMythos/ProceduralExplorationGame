#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class PerformFinalFloodFillMapGenStep : public MapGenStep{
    public:
        PerformFinalFloodFillMapGenStep();
        ~PerformFinalFloodFillMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PerformFinalFloodFillMapGenJob{
    public:
        PerformFinalFloodFillMapGenJob();
        ~PerformFinalFloodFillMapGenJob();

        void processJob(ExplorationMapData* mapData);

    };

}
