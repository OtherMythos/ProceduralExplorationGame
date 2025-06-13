#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "Util/FloodFill.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class IsolateRegionsMapGenStep : public MapGenStep{
    public:
        IsolateRegionsMapGenStep();
        ~IsolateRegionsMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;

    private:
        typedef AV::uint32 WrappedAltitudeRegion;

        static inline bool comparisonValues(ExplorationMapData* mapData, WrappedAltitudeRegion val);
        static inline WrappedAltitudeRegion readValues(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y);

        void isolateRegion(ExplorationMapData* mapData, RegionData& region, std::vector<RegionId>& vals);

    };

    class IsolateRegionsMapGenJob{
    public:
        IsolateRegionsMapGenJob();
        ~IsolateRegionsMapGenJob();

        void processJob(ExplorationMapData* mapData, const std::vector<WorldPoint>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
