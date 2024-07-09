#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class RemoveRedundantIslandsMapGenStep : public MapGenStep{
    public:
        RemoveRedundantIslandsMapGenStep();
        ~RemoveRedundantIslandsMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData) override;
    };

    class RemoveRedundantIslandsMapGenJob{
    public:
        RemoveRedundantIslandsMapGenJob();
        ~RemoveRedundantIslandsMapGenJob();

        void processJob(ExplorationMapData* mapData);

    };

}
