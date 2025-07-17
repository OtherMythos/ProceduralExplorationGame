#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateRegionDistanceMapGenStep : public MapGenStep{
    public:
        CalculateRegionDistanceMapGenStep();
        ~CalculateRegionDistanceMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class CalculateRegionDistanceMapGenJob{
    public:
        CalculateRegionDistanceMapGenJob();
        ~CalculateRegionDistanceMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
