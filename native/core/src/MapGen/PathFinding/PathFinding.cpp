#include "PathFinding.h"
//#include "Biomes/BiomePrerequisites.h"
#include "MapGen/BaseClient/Steps/PerlinNoise.h"

#include <cmath>
#include <algorithm>
#include <cassert>

namespace ProceduralExplorationGameCore{

    bool PathFinding::isWalkableForPath(const ExplorationMapData* mapData, WorldCoord x, WorldCoord y){
        if(x<0||y<0||x>=mapData->width||y>=mapData->height){
            return false;
        }

        WorldPoint p=WRAP_WORLD_POINT(x, y);

        //Check water
        WaterId waterGroup=*WATER_GROUP_PTR_FOR_COORD_CONST(mapData, p);
        if(waterGroup!=INVALID_WATER_ID){
            return false;
        }

        //Check altitude (sea level or higher)
        AV::uint8 altitude=*VOX_PTR_FOR_COORD_CONST(mapData, p);
        if(altitude<mapData->seaLevel){
            return false;
        }

        //Could add more checks for placed items, steep terrain, etc.

        return true;
    }

    float PathFinding::heuristic(WorldCoord x1, WorldCoord y1, WorldCoord x2, WorldCoord y2){
        //Manhattan distance
        int dx=static_cast<int>(x1)-static_cast<int>(x2);
        int dy=static_cast<int>(y1)-static_cast<int>(y2);
        return static_cast<float>(std::abs(dx)+std::abs(dy));
    }

    float PathFinding::getMovementCost(const ExplorationMapData* mapData, WorldCoord fromX, WorldCoord fromY, WorldCoord toX, WorldCoord toY){
        if(!isWalkableForPath(mapData, toX, toY)){
            return 999999.0f; //Impassable
        }

        //Get altitude of destination
        WorldPoint p=WRAP_WORLD_POINT(toX, toY);
        AV::uint8 altitude=*VOX_PTR_FOR_COORD_CONST(mapData, p);

        //Penalize tiles too close to sea level to avoid underwater paths
        float altitudeCost=1.0f;
        AV::uint8 minSafeAltitude=mapData->seaLevel+5; //At least 5 units above sea level
        if(altitude<minSafeAltitude){
            //Heavy penalty for tiles barely above sea level
            altitudeCost+=(minSafeAltitude-altitude)*2.0f;
        }

        //Diagonal movement costs slightly more
        int dx=static_cast<int>(toX)-static_cast<int>(fromX);
        int dy=static_cast<int>(toY)-static_cast<int>(fromY);

        float baseCost=1.0f;
        if(dx!=0&&dy!=0){
            baseCost=1.41f; //sqrt(2) for diagonal
        }

        return baseCost*altitudeCost;
    }

    bool PathFinding::generatePath(
        const ExplorationMapData* mapData,
        WorldCoord startX, WorldCoord startY,
        WorldCoord endX, WorldCoord endY,
        AV::uint8 pathId,
        PathSegment& outSegment){

        if(!isWalkableForPath(mapData, startX, startY)||!isWalkableForPath(mapData, endX, endY)){
            return false;
        }

        //Open and closed sets
        std::priority_queue<PathNode> openSet;
        std::map<std::pair<WorldCoord, WorldCoord>, PathNode*> allNodes;
        std::set<std::pair<WorldCoord, WorldCoord>> closedSet;

        //Start node
        PathNode* startNode=new PathNode(startX, startY, 0.0f, heuristic(startX, startY, endX, endY));
        openSet.push(*startNode);
        allNodes[{startX, startY}]=startNode;

        PathNode* current=nullptr;
        bool pathFound=false;

        //A* main loop
        while(!openSet.empty()){
            current=new PathNode(openSet.top());
            openSet.pop();

            if(current->x==endX&&current->y==endY){
                pathFound=true;
                break;
            }

            closedSet.insert({current->x, current->y});

            //Check 8 neighbors (including diagonals)
            for(int dx=-1; dx<=1; dx++){
                for(int dy=-1; dy<=1; dy++){
                    if(dx==0&&dy==0) continue;

                    WorldCoord nx=current->x+dx;
                    WorldCoord ny=current->y+dy;

                    if(!isWalkableForPath(mapData, nx, ny)) continue;
                    if(closedSet.count({nx, ny})) continue;

                    float moveCost=getMovementCost(mapData, current->x, current->y, nx, ny);
                    if(moveCost>999.0f) continue;

                    float gCost=current->gCost+moveCost;
                    float hCost=heuristic(nx, ny, endX, endY);

                    auto it=allNodes.find({nx, ny});
                    if(it==allNodes.end()){
                        PathNode* newNode=new PathNode(nx, ny, gCost, hCost, current);
                        allNodes[{nx, ny}]=newNode;
                        openSet.push(*newNode);
                    }else if(gCost<it->second->gCost){
                        it->second->gCost=gCost;
                        it->second->parent=current;
                    }
                }
            }
        }

        if(!pathFound){
            //Cleanup
            for(auto& p : allNodes) delete p.second;
            return false;
        }

        //Reconstruct path
        std::vector<WorldPoint> pathPoints;
        PathNode* node=current;
        while(node!=nullptr){
            pathPoints.push_back(WRAP_WORLD_POINT(node->x, node->y));
            node=node->parent;
        }
        std::reverse(pathPoints.begin(), pathPoints.end());

        //Use A* path directly without meander effects
        std::vector<WorldPoint>& meanderPoints=pathPoints;

        outSegment.origin=pathPoints.front();
        outSegment.points=meanderPoints;
        outSegment.pathId=pathId;
        outSegment.difficulty=1;
        outSegment.width=3;
        outSegment.region=INVALID_REGION_ID;

        //Cleanup
        for(auto& p : allNodes) delete p.second;

        return true;
    }
}
