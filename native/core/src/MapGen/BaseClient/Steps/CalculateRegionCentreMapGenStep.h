#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateRegionCentreMapGenStep : public MapGenStep{
    public:
        CalculateRegionCentreMapGenStep();
        ~CalculateRegionCentreMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class CalculateRegionCentreMapGenJob{
    public:
        CalculateRegionCentreMapGenJob();
        ~CalculateRegionCentreMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
