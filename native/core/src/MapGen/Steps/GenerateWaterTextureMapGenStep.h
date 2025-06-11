#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateWaterTextureMapGenStep : public MapGenStep{
    public:
        GenerateWaterTextureMapGenStep();
        ~GenerateWaterTextureMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class GenerateWaterTextureMapGenJob{
    public:
        GenerateWaterTextureMapGenJob();
        ~GenerateWaterTextureMapGenJob();

        void processJob(ExplorationMapData* mapData, float* buffer, float* bufferMask, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
