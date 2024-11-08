#pragma once

#include "MapGenStep.h"

#include <vector>

#include "GamePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class MergeAltitudeMapGenStep : public MapGenStep{
    public:
        MergeAltitudeMapGenStep();
        ~MergeAltitudeMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class MergeAltitudeMapGenJob{
    public:
        MergeAltitudeMapGenJob();
        ~MergeAltitudeMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb, const std::vector<float>& additionVals);

    };

}