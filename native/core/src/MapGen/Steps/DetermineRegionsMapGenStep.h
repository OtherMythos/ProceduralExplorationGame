#pragma once

#include "MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

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

        void processJob(ExplorationMapData* mapData, const std::vector<WorldPoint>& points, std::vector<RegionData>& regionData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb);

    };

}
