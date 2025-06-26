#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class CalculateRegionEdgesMapGenStep : public MapGenStep{
    public:
        CalculateRegionEdgesMapGenStep();
        ~CalculateRegionEdgesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class CalculateRegionEdgesMapGenJob{
    public:
        CalculateRegionEdgesMapGenJob();
        ~CalculateRegionEdgesMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    };

}
