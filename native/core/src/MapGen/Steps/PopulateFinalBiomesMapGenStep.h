#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class PopulateFinalBiomesMapGenStep : public MapGenStep{
    public:
        PopulateFinalBiomesMapGenStep();
        ~PopulateFinalBiomesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PopulateFinalBiomesMapGenJob{
    public:
        PopulateFinalBiomesMapGenJob();
        ~PopulateFinalBiomesMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
