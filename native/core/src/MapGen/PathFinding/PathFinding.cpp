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

        //Apply Catmull-Rom spline smoothing for organic wavy paths
        std::vector<WorldPoint> smoothedPoints=applyCatmullRomSmoothing(mapData, pathPoints, 4);

        //Connect the smoothed points with Bresenham lines to fill gaps
        std::vector<WorldPoint> connectedPoints=connectPathPoints(smoothedPoints);

        outSegment.origin=pathPoints.front();
        outSegment.points=connectedPoints;
        outSegment.pathId=pathId;
        outSegment.difficulty=1;
        outSegment.width=3;
        outSegment.region=INVALID_REGION_ID;

        //Cleanup
        for(auto& p : allNodes) delete p.second;

        return true;
    }

    void PathFinding::catmullRomPoint(float t, float p0x, float p0y, float p1x, float p1y, float p2x, float p2y, float p3x, float p3y, float& outX, float& outY){
        //Catmull-Rom spline formula
        //P(t) = 0.5 * ((2*P1) + (-P0 + P2)*t + (2*P0 - 5*P1 + 4*P2 - P3)*t^2 + (-P0 + 3*P1 - 3*P2 + P3)*t^3)
        float t2=t*t;
        float t3=t2*t;

        outX=0.5f*((2.0f*p1x)+
            (-p0x+p2x)*t+
            (2.0f*p0x-5.0f*p1x+4.0f*p2x-p3x)*t2+
            (-p0x+3.0f*p1x-3.0f*p2x+p3x)*t3);

        outY=0.5f*((2.0f*p1y)+
            (-p0y+p2y)*t+
            (2.0f*p0y-5.0f*p1y+4.0f*p2y-p3y)*t2+
            (-p0y+3.0f*p1y-3.0f*p2y+p3y)*t3);
    }

    std::vector<WorldPoint> PathFinding::applyCatmullRomSmoothing(const ExplorationMapData* mapData, const std::vector<WorldPoint>& path, int subdivisions){
        if(path.size()<2){
            return path;
        }

        //For very short paths, just return the original
        if(path.size()<4){
            return path;
        }

        //Step 1: Downsample the path to get control points every N tiles
        //This creates the "skeleton" that we'll add waviness to
        int sampleInterval=8; //Take a control point every 8 tiles
        std::vector<WorldPoint> controlPoints;
        controlPoints.push_back(path.front()); //Always include start

        for(size_t i=sampleInterval; i<path.size()-1; i+=sampleInterval){
            controlPoints.push_back(path[i]);
        }
        controlPoints.push_back(path.back()); //Always include end

        if(controlPoints.size()<4){
            return path; //Not enough points to make wavy
        }

        //Step 2: Add perpendicular offsets to middle control points for waviness
        float waveAmplitude=1.0f; //Maximum offset in tiles
        std::vector<std::pair<float, float>> offsetControlPoints;

        for(size_t i=0; i<controlPoints.size(); i++){
            WorldCoord cx, cy;
            READ_WORLD_POINT(controlPoints[i], cx, cy);

            float fx=static_cast<float>(cx);
            float fy=static_cast<float>(cy);

            //Don't offset start or end points
            if(i>0&&i<controlPoints.size()-1){
                //Calculate direction to next point
                WorldCoord nx, ny, px, py;
                READ_WORLD_POINT(controlPoints[i+1], nx, ny);
                READ_WORLD_POINT(controlPoints[i-1], px, py);

                float dirX=static_cast<float>(nx)-static_cast<float>(px);
                float dirY=static_cast<float>(ny)-static_cast<float>(py);

                //Normalise direction
                float len=std::sqrt(dirX*dirX+dirY*dirY);
                if(len>0.001f){
                    dirX/=len;
                    dirY/=len;
                }

                //Perpendicular vector (rotate 90 degrees)
                float perpX=-dirY;
                float perpY=dirX;

                //Use a simple deterministic "random" based on position
                //This creates consistent waves for the same path
                float noise=std::sin(static_cast<float>(i)*2.5f+static_cast<float>(cx)*0.1f)*waveAmplitude;

                fx+=perpX*noise;
                fy+=perpY*noise;
            }

            offsetControlPoints.push_back({fx, fy});
        }

        //Step 3: Apply Catmull-Rom interpolation through the offset control points
        std::vector<WorldPoint> smoothedPath;
        smoothedPath.push_back(path.front()); //Always keep exact start point

        //Iterate through segments of offset control points
        for(size_t i=0; i<offsetControlPoints.size()-1; i++){
            //Get the 4 control points for this segment (clamp at boundaries)
            size_t idx0=(i==0) ? 0 : i-1;
            size_t idx1=i;
            size_t idx2=i+1;
            size_t idx3=(i+2>=offsetControlPoints.size()) ? offsetControlPoints.size()-1 : i+2;

            float p0x=offsetControlPoints[idx0].first;
            float p0y=offsetControlPoints[idx0].second;
            float p1x=offsetControlPoints[idx1].first;
            float p1y=offsetControlPoints[idx1].second;
            float p2x=offsetControlPoints[idx2].first;
            float p2y=offsetControlPoints[idx2].second;
            float p3x=offsetControlPoints[idx3].first;
            float p3y=offsetControlPoints[idx3].second;

            //Calculate how many subdivisions for this segment based on distance
            float segDist=std::sqrt((p2x-p1x)*(p2x-p1x)+(p2y-p1y)*(p2y-p1y));
            int segSubdivisions=std::max(4, static_cast<int>(segDist/2.0f));

            //Generate interpolated points along the spline segment
            for(int s=1; s<=segSubdivisions; s++){
                float t=static_cast<float>(s)/static_cast<float>(segSubdivisions);

                float outX, outY;
                catmullRomPoint(t, p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y, outX, outY);

                WorldCoord newX=static_cast<WorldCoord>(std::round(outX));
                WorldCoord newY=static_cast<WorldCoord>(std::round(outY));

                //Clamp to map bounds
                if(newX<0) newX=0;
                if(newY<0) newY=0;
                if(newX>=mapData->width) newX=mapData->width-1;
                if(newY>=mapData->height) newY=mapData->height-1;

                WorldPoint newPoint=WRAP_WORLD_POINT(newX, newY);

                //Only add if different from last point (avoid duplicates)
                if(smoothedPath.empty()||smoothedPath.back()!=newPoint){
                    //Verify the point is walkable, otherwise keep original path point
                    if(isWalkableForPath(mapData, newX, newY)){
                        smoothedPath.push_back(newPoint);
                    }
                }
            }
        }

        //Ensure end point is included
        if(smoothedPath.empty()||smoothedPath.back()!=path.back()){
            smoothedPath.push_back(path.back());
        }

        return smoothedPath;
    }

    void PathFinding::bresenhamLine(WorldCoord x0, WorldCoord y0, WorldCoord x1, WorldCoord y1, std::vector<WorldPoint>& outPoints){
        int dx=std::abs(static_cast<int>(x1)-static_cast<int>(x0));
        int dy=-std::abs(static_cast<int>(y1)-static_cast<int>(y0));
        int sx=(x0<x1) ? 1 : -1;
        int sy=(y0<y1) ? 1 : -1;
        int err=dx+dy;

        WorldCoord x=x0;
        WorldCoord y=y0;

        while(true){
            outPoints.push_back(WRAP_WORLD_POINT(x, y));

            if(x==x1&&y==y1) break;

            int e2=2*err;
            if(e2>=dy){
                err+=dy;
                x+=sx;
            }
            if(e2<=dx){
                err+=dx;
                y+=sy;
            }
        }
    }

    std::vector<WorldPoint> PathFinding::connectPathPoints(const std::vector<WorldPoint>& path){
        if(path.size()<2){
            return path;
        }

        std::vector<WorldPoint> connectedPath;

        for(size_t i=0; i<path.size()-1; i++){
            WorldCoord x0, y0, x1, y1;
            READ_WORLD_POINT(path[i], x0, y0);
            READ_WORLD_POINT(path[i+1], x1, y1);

            //Get all points along the line between these two points
            std::vector<WorldPoint> linePoints;
            bresenhamLine(x0, y0, x1, y1, linePoints);

            //Add all points except the last one (to avoid duplicates with next segment)
            for(size_t j=0; j<linePoints.size()-1; j++){
                connectedPath.push_back(linePoints[j]);
            }
        }

        //Add the final point
        connectedPath.push_back(path.back());

        return connectedPath;
    }
}
