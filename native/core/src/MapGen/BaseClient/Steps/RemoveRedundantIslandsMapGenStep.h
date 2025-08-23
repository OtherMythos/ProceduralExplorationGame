#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class RemoveRedundantIslandsMapGenStep : public MapGenStep{
    public:
        RemoveRedundantIslandsMapGenStep();
        ~RemoveRedundantIslandsMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class RemoveRedundantIslandsMapGenJob{
    public:
        RemoveRedundantIslandsMapGenJob();
        ~RemoveRedundantIslandsMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
