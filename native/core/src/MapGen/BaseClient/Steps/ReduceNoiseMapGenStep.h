#pragma once

#include "MapGen/MapGenStep.h"

#include <vector>

#include "GamePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class ReduceNoiseMapGenStep : public MapGenStep{
    public:
        ReduceNoiseMapGenStep();
        ~ReduceNoiseMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class ReduceNoiseMapGenJob{
    public:
        ReduceNoiseMapGenJob();
        ~ReduceNoiseMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb, const std::vector<float>& additionVals);

    };

}
