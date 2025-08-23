#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateWaterDistanceMapGenStep : public MapGenStep{
    public:
        CalculateWaterDistanceMapGenStep();
        ~CalculateWaterDistanceMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class CalculateWaterDistanceMapGenJob{
    public:
        CalculateWaterDistanceMapGenJob();
        ~CalculateWaterDistanceMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
