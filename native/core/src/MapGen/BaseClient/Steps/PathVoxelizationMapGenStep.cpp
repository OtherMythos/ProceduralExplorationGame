#include "PathVoxelizationMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include <set>
#include <map>
#include <cmath>
#include <vector>
#include <limits>
#include <string>
#include <utility>

namespace ProceduralExplorationGameCore{

    static const int PATH_THICKNESS = 1; //Radius of thickened path
    static const AV::uint8 PATH_COLOUR_VALUE = 250;
    static const AV::uint8 PATH_DIRT_COLOUR_VALUE = 131; //Colour for dirt paths far from civilisation
    static const float DIRT_PATH_DISTANCE_THRESHOLD = 80.0f; //Distance (in voxels) from a place beyond which paths become dirt
    static const float DIRT_PATH_DISTANCE_DEVIATION_MAX = 40.0f; //Max random reduction to DIRT_PATH_DISTANCE_THRESHOLD applied per path segment

    PathVoxelizationMapGenStep::PathVoxelizationMapGenStep() : MapGenStep("Path Voxelization"){
    }

    PathVoxelizationMapGenStep::~PathVoxelizationMapGenStep(){
    }

    bool PathVoxelizationMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<PathSegment>& pathData = *mapData->ptr<std::vector<PathSegment>>("pathData");

        //Load place node positions for civilisation distance checks
        //Wilderness/end nodes are not stored here, only place nodes
        std::vector<std::pair<WorldCoord, WorldCoord>> placeNodePositions;
        AV::uint32 placeNodeCount = mapData->uint32("pathSpawnNodeCount");
        for(AV::uint32 i = 0; i < placeNodeCount; i++){
            WorldCoord nx = static_cast<WorldCoord>(mapData->uint32("pathNode_originX_" + std::to_string(i)));
            WorldCoord ny = static_cast<WorldCoord>(mapData->uint32("pathNode_originY_" + std::to_string(i)));
            placeNodePositions.push_back({nx, ny});
        }

        //Initialize all path IDs to INVALID_PATH_ID
        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                PathId* pathIdPtr = PATH_ID_PTR_FOR_COORD(mapData, p);
                *pathIdPtr = INVALID_PATH_ID;
            }
        }

        //Collect all expanded path points mapped to their segment's effective dirt threshold
        //Using emplace so the first segment to claim a voxel determines its threshold
        std::map<std::pair<WorldCoord, WorldCoord>, float> expandedPathThresholds;

        for(PathSegment& segment : pathData){
            //Create a separate set for this path's expanded points
            std::set<std::pair<WorldCoord, WorldCoord>> segmentExpandedPoints;

            //Generate a seeded random deviation for this segment and subtract from the base threshold
            float deviation = static_cast<float>(mapGenRandomIntMinMax(0, static_cast<size_t>(DIRT_PATH_DISTANCE_DEVIATION_MAX)));
            float effectiveThreshold = DIRT_PATH_DISTANCE_THRESHOLD - deviation;

            for(size_t i = 0; i < segment.points.size(); i++){
                WorldPoint p = segment.points[i];
                WorldCoord x, y;
                READ_WORLD_POINT(p, x, y);

                //Expand this point into a box of thickness
                for(int dx = -PATH_THICKNESS; dx <= PATH_THICKNESS; dx++){
                    for(int dy = -PATH_THICKNESS; dy <= PATH_THICKNESS; dy++){
                        WorldCoord expandedX = x + dx;
                        WorldCoord expandedY = y + dy;

                        //Check bounds
                        if(expandedX < 0 || expandedY < 0 || expandedX >= mapData->width || expandedY >= mapData->height) continue;

                        segmentExpandedPoints.insert({expandedX, expandedY});
                    }
                }
            }

            //Store expanded points on the segment and record the effective threshold for each coord
            for(const auto& coord : segmentExpandedPoints){
                segment.pointsExpanded.push_back(WRAP_WORLD_POINT(coord.first, coord.second));
                //emplace keeps the first segment's threshold if a voxel is shared
                expandedPathThresholds.emplace(coord, effectiveThreshold);
            }
        }

        //Now mark all expanded path points in the voxel buffer
        int pathIdx = 0;
        for(const auto& entry : expandedPathThresholds){
            WorldCoord x = entry.first.first;
            WorldCoord y = entry.first.second;
            float effectiveThreshold = entry.second;

            WorldPoint p = WRAP_WORLD_POINT(x, y);

            //Write path ID to tertiary buffer byte 1
            PathId* pathIdPtr = PATH_ID_PTR_FOR_COORD(mapData, p);
            *pathIdPtr = pathIdx;

            //Set speed modifier to 1.25x (0x1)
            VOXEL_META_SET_SPEED_MODIFIER(mapData, p, 0x2);

            //Set DO_NOT_PLACE_TREES flag in tertiary buffer
            AV::uint32* fullTertiaryVoxPtr = FULL_PTR_FOR_COORD_TERTIARY(mapData, p);
            *fullTertiaryVoxPtr |= DO_NOT_PLACE_ITEMS_VOXEL_FLAG;

            //Set DRAW_COLOUR_VOXEL_FLAG to use direct colour value
            *fullTertiaryVoxPtr |= DRAW_COLOUR_VOXEL_FLAG;

            //Set colour value; dirt path if too far from any place (civilisation)
            AV::uint8* voxPtr = VOX_VALUE_PTR_FOR_COORD(mapData, p);
            AV::uint8 colourValue = PATH_COLOUR_VALUE;
            if(!placeNodePositions.empty()){
                float minDist = std::numeric_limits<float>::max();
                for(const auto& placePos : placeNodePositions){
                    float dx = static_cast<float>(static_cast<int>(x) - static_cast<int>(placePos.first));
                    float dy = static_cast<float>(static_cast<int>(y) - static_cast<int>(placePos.second));
                    float dist = std::sqrt(dx * dx + dy * dy);
                    if(dist < minDist) minDist = dist;
                }
                if(minDist > effectiveThreshold){
                    colourValue = PATH_DIRT_COLOUR_VALUE;
                }
            }
            *voxPtr = colourValue;

            pathIdx++;
        }

        return true;
    }
}
