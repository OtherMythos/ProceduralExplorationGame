#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class DetermineRegionsMapGenStep : public MapGenStep{
    public:
        DetermineRegionsMapGenStep();
        ~DetermineRegionsMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class DetermineRegionsMapGenJob{
    public:
        DetermineRegionsMapGenJob();
        ~DetermineRegionsMapGenJob();

        void processJob(ExplorationMapData* mapData, const std::vector<WorldPoint>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
