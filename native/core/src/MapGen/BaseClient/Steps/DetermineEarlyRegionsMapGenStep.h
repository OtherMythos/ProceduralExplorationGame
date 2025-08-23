#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    struct RegionSeedData{
        WorldPoint p;
        AV::uint8 size;
    };

    class DetermineEarlyRegionsMapGenStep : public MapGenStep{
    public:
        DetermineEarlyRegionsMapGenStep();
        ~DetermineEarlyRegionsMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class DetermineEarlyRegionsMapGenJob{
    public:
        DetermineEarlyRegionsMapGenJob();
        ~DetermineEarlyRegionsMapGenJob();

        void processJob(ExplorationMapData* mapData, const std::vector<RegionSeedData>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
