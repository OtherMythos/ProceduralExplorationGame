#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class PerformFloodFillMapGenStep : public MapGenStep{
    public:
        PerformFloodFillMapGenStep();
        ~PerformFloodFillMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData) override;
    };

    class PerformFloodFillMapGenJob{
    public:
        PerformFloodFillMapGenJob();
        ~PerformFloodFillMapGenJob();

        void processJob(ExplorationMapData* mapData);

    };

}
