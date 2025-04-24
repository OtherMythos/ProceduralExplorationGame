#pragma once

#include "MapGen/MapGenStep.h"

#include "GamePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class GenerateNoiseMapGenStep : public MapGenStep{
    public:
        GenerateNoiseMapGenStep();
        ~GenerateNoiseMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class GenerateNoiseMapGenJob{
    public:
        GenerateNoiseMapGenJob();
        ~GenerateNoiseMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
