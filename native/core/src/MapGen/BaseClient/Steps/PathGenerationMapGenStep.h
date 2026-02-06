#pragma once

#include "MapGen/MapGenStep.h"

#include <vector>
#include "System/EnginePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct PathNode{
        WorldCoord originX, originY;
        RegionId region;
        AV::uint8 pathSpawns;
        bool canReceivePaths;
        AV::uint8 connectivity;
    };

    class PathGenerationMapGenStep : public MapGenStep{
    public:
        PathGenerationMapGenStep();
        virtual ~PathGenerationMapGenStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    private:
        void generateWildernessPathNodes(ExplorationMapData* mapData, std::vector<PathSegment>& pathData, const std::vector<PathNode>& pathNodes, AV::uint8& pathId);
    };
}
