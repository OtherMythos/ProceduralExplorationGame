#pragma once

#include "System/EnginePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <vector>
#include <queue>
#include <set>

namespace ProceduralExplorationGameCore{

    class PathFinding{
    public:
        PathFinding()=delete;
        ~PathFinding()=delete;

        //Check if a coordinate is walkable for path generation
        static bool isWalkableForPath(const ExplorationMapData* mapData, WorldCoord x, WorldCoord y);

        //Generate a path from start to end using A* with Perlin noise injection for meanders
        //Returns false if no path found, true if successful (path stored in outSegment)
        static bool generatePath(
            const ExplorationMapData* mapData,
            WorldCoord startX, WorldCoord startY,
            WorldCoord endX, WorldCoord endY,
            AV::uint8 pathId,
            PathSegment& outSegment
        );

    private:
        struct PathNode{
            WorldCoord x, y;
            float gCost;  //Cost from start
            float hCost;  //Heuristic cost to end
            PathNode* parent;

            PathNode(WorldCoord x_, WorldCoord y_, float g, float h, PathNode* p=nullptr)
                : x(x_), y(y_), gCost(g), hCost(h), parent(p){}

            float getFCost() const{ return gCost+hCost; }

            bool operator<(const PathNode& other) const{
                //For priority queue (min-heap)
                return getFCost()>other.getFCost();
            }
        };

        static float heuristic(WorldCoord x1, WorldCoord y1, WorldCoord x2, WorldCoord y2);
        static float getMovementCost(const ExplorationMapData* mapData, WorldCoord fromX, WorldCoord fromY, WorldCoord toX, WorldCoord toY);

        //Catmull-Rom spline smoothing for organic paths
        static void catmullRomPoint(float t, float p0x, float p0y, float p1x, float p1y, float p2x, float p2y, float p3x, float p3y, float& outX, float& outY);
        static std::vector<WorldPoint> applyCatmullRomSmoothing(const ExplorationMapData* mapData, const std::vector<WorldPoint>& path, int subdivisions);

        //Bresenham line to connect discrete points
        static void bresenhamLine(WorldCoord x0, WorldCoord y0, WorldCoord x1, WorldCoord y1, std::vector<WorldPoint>& outPoints);
        static std::vector<WorldPoint> connectPathPoints(const std::vector<WorldPoint>& path);
    };
}
