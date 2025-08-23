#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class RemoveRedundantWaterMapGenStep : public MapGenStep{
    public:
        RemoveRedundantWaterMapGenStep();
        ~RemoveRedundantWaterMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class RemoveRedundantWaterMapGenJob{
    public:
        RemoveRedundantWaterMapGenJob();
        ~RemoveRedundantWaterMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
