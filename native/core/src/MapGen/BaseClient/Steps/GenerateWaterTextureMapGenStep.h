#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateWaterTextureMapGenStep : public MapGenStep{
    public:
        GenerateWaterTextureMapGenStep();
        ~GenerateWaterTextureMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class GenerateWaterTextureMapGenJob{
    public:
        GenerateWaterTextureMapGenJob();
        ~GenerateWaterTextureMapGenJob();

        void processJob(ExplorationMapData* mapData, float* buffer, float* bufferMask, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
