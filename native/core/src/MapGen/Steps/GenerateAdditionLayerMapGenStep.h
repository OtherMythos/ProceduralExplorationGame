#pragma once

#include "MapGenStep.h"

#include "GamePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class GenerateAdditionLayerMapGenStep : public MapGenStep{
    public:
        GenerateAdditionLayerMapGenStep();
        ~GenerateAdditionLayerMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class GenerateAdditionLayerMapGenJob{
    public:
        GenerateAdditionLayerMapGenJob();
        ~GenerateAdditionLayerMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
