#include "PathVoxelizationMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include <set>

namespace ProceduralExplorationGameCore{

    static const int PATH_THICKNESS=0;//Radius of thickened path
    static const AV::uint8 PATH_COLOUR_VALUE=250;

    PathVoxelizationMapGenStep::PathVoxelizationMapGenStep() : MapGenStep("Path Voxelization"){
    }

    PathVoxelizationMapGenStep::~PathVoxelizationMapGenStep(){
    }

    bool PathVoxelizationMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<PathSegment>& pathData=*mapData->ptr<std::vector<PathSegment>>("pathData");

        //Collect all expanded path points into a set to avoid duplicates
        std::set<std::pair<WorldCoord, WorldCoord>> expandedPathPoints;

        for(const PathSegment& segment : pathData){
            for(size_t i=0; i<segment.points.size(); i++){
                WorldPoint p=segment.points[i];
                WorldCoord x, y;
                READ_WORLD_POINT(p, x, y);

                //Expand this point into a box of thickness
                for(int dx=-PATH_THICKNESS; dx<=PATH_THICKNESS; dx++){
                    for(int dy=-PATH_THICKNESS; dy<=PATH_THICKNESS; dy++){
                        WorldCoord expandedX=x+dx;
                        WorldCoord expandedY=y+dy;

                        //Check bounds
                        if(expandedX<0||expandedY<0||expandedX>=mapData->width||expandedY>=mapData->height) continue;

                        expandedPathPoints.insert({expandedX, expandedY});
                    }
                }
            }
        }

        //Now mark all expanded path points in the voxel buffer
        int pathIdx=0;
        for(const auto& coord : expandedPathPoints){
            WorldCoord x=coord.first;
            WorldCoord y=coord.second;

            WorldPoint p=WRAP_WORLD_POINT(x, y);

            //Write path ID to tertiary buffer byte 1
            AV::uint8* pathIdPtr=PATH_ID_PTR_FOR_COORD(mapData, p);
            *pathIdPtr=pathIdx;

            //Set DO_NOT_PLACE_TREES flag in secondary buffer
            AV::uint8* flagsPtr=VOXEL_FLAGS_PTR_FOR_COORD(mapData, p);
            *flagsPtr|=DO_NOT_PLACE_ITEMS_VOXEL_FLAG;

            //Set DRAW_COLOUR_VOXEL_FLAG to use direct colour value
            *flagsPtr|=DRAW_COLOUR_VOXEL_FLAG;

            //Set colour value to 248
            AV::uint8* voxPtr=VOX_VALUE_PTR_FOR_COORD(mapData, p);
            *voxPtr=PATH_COLOUR_VALUE;

            pathIdx++;
        }

        return true;
    }
}
