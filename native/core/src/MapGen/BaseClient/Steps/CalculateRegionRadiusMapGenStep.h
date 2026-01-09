#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateRegionRadiusMapGenStep : public MapGenStep{
    public:
        CalculateRegionRadiusMapGenStep();
        ~CalculateRegionRadiusMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class CalculateRegionRadiusMapGenJob{
    public:
        CalculateRegionRadiusMapGenJob();
        ~CalculateRegionRadiusMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
