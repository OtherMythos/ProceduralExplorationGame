#include "PathGenerationMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/PathFinding/PathFinding.h"

#include <cmath>
#include <algorithm>
#include <string>
#include <vector>
#include <set>
#include <limits>

namespace ProceduralExplorationGameCore{

    PathGenerationMapGenStep::PathGenerationMapGenStep() : MapGenStep("Path Generation"){
    }

    PathGenerationMapGenStep::~PathGenerationMapGenStep(){
    }

    static float distanceBetweenPoints(WorldCoord x1, WorldCoord y1, WorldCoord x2, WorldCoord y2){
        float dx=static_cast<float>(static_cast<int>(x1)-static_cast<int>(x2));
        float dy=static_cast<float>(static_cast<int>(y1)-static_cast<int>(y2));
        return std::sqrt(dx*dx+dy*dy);
    }

    bool PathGenerationMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<PathSegment>& pathData=*mapData->ptr<std::vector<PathSegment>>("pathData");

        //Read path spawn nodes from mapData (populated by Squirrel step)
        AV::uint32 nodeCount=mapData->uint32("pathSpawnNodeCount");

        if(nodeCount==0){
            return true;
        }

        //Load all path nodes
        std::vector<PathNode> pathNodes;
        for(AV::uint32 i=0; i<nodeCount; i++){
            PathNode node;
            node.originX=static_cast<WorldCoord>(mapData->uint32("pathNode_originX_"+std::to_string(i)));
            node.originY=static_cast<WorldCoord>(mapData->uint32("pathNode_originY_"+std::to_string(i)));
            node.region=static_cast<RegionId>(mapData->uint32("pathNode_region_"+std::to_string(i)));
            node.pathSpawns=static_cast<AV::uint8>(mapData->uint32("pathNode_pathSpawns_"+std::to_string(i)));
            node.canReceivePaths=(mapData->uint32("pathNode_canReceive_"+std::to_string(i))!=0);
            node.connectivity=static_cast<AV::uint8>(mapData->uint32("pathNode_connectivity_"+std::to_string(i)));
            pathNodes.push_back(node);
        }

        //Track which place pairs are already connected to prevent duplicate links
        std::set<std::pair<size_t, size_t>> connectedPairs;

        //For each path spawn node, find destination nodes and generate paths
        AV::uint8 pathId=0;
        for(size_t sourceIdx=0; sourceIdx<pathNodes.size(); sourceIdx++){
            const PathNode& sourceNode=pathNodes[sourceIdx];
            if(pathId>=255) break; //Max 255 path IDs

            //Find nearby destination nodes
            std::vector<std::pair<float, size_t>> destinationCandidates;
            for(size_t destIdx=0; destIdx<pathNodes.size(); destIdx++){
                if(destIdx==sourceIdx) continue; //Skip self

                const PathNode& destNode=pathNodes[destIdx];
                if(!destNode.canReceivePaths) continue; //Skip non-receiving nodes

                //Skip if this pair is already connected
                std::pair<size_t, size_t> pair={sourceIdx, destIdx};
                if(connectedPairs.count(pair)) continue;

                float dist=distanceBetweenPoints(
                    sourceNode.originX, sourceNode.originY,
                    destNode.originX, destNode.originY
                );

                destinationCandidates.push_back({dist, destIdx});
            }

            //Sort by distance and take closest N destinations
            std::sort(destinationCandidates.begin(), destinationCandidates.end());

            AV::uint8 pathsToGenerate=std::min(static_cast<AV::uint8>(sourceNode.pathSpawns), static_cast<AV::uint8>(destinationCandidates.size()));

            for(AV::uint8 i=0; i<pathsToGenerate&&pathId<255; i++){
                size_t destIdx=destinationCandidates[i].second;
                const PathNode& destNode=pathNodes[destIdx];

                PathSegment segment;
                if(PathFinding::generatePath(
                    mapData,
                    sourceNode.originX, sourceNode.originY,
                    destNode.originX, destNode.originY,
                    pathId,
                    segment
                )){
                    pathData.push_back(segment);
                    connectedPairs.insert({sourceIdx, destIdx});
                    pathId++;
                }
            }
        }

        //Generate wilderness path nodes to give impression of paths leading to nowhere
        generateWildernessPathNodes(mapData, pathData, pathNodes, pathId);

        return true;
    }

    void PathGenerationMapGenStep::generateWildernessPathNodes(ExplorationMapData* mapData, std::vector<PathSegment>& pathData, const std::vector<PathNode>& pathNodes, AV::uint8& pathId){
        const AV::uint32 seaLevel=mapData->uint32("seaLevel");
        const int numWildernessNodes=5; //Number of wilderness nodes to generate
        const float minDistanceFromPlaces=100.0f; //Minimum distance from existing path nodes

        std::vector<PathNode> wildernessNodes;

        //Generate random wilderness nodes on valid land
        int attemptsPerNode=20;
        for(int n=0; n<numWildernessNodes; n++){
            bool found=false;
            for(int attempt=0; attempt<attemptsPerNode&&!found; attempt++){
                WorldCoord x=mapGenRandomIntMinMax(0, mapData->width-1);
                WorldCoord y=mapGenRandomIntMinMax(0, mapData->height-1);

                //Check if this location is valid
                if(!PathFinding::isWalkableForPath(mapData, x, y)){
                    continue;
                }

                //Check it's far enough from existing path nodes
                bool tooCloseToPlace=false;
                for(const PathNode& place : pathNodes){
                    float dist=distanceBetweenPoints(x, y, place.originX, place.originY);
                    if(dist<minDistanceFromPlaces){
                        tooCloseToPlace=true;
                        break;
                    }
                }

                if(tooCloseToPlace){
                    continue;
                }

                //Valid wilderness node found
                PathNode wildNode;
                wildNode.originX=x;
                wildNode.originY=y;
                wildNode.region=INVALID_REGION_ID;
                wildNode.pathSpawns=0; //Wilderness nodes don't spawn paths
                wildNode.canReceivePaths=true;
                wildNode.connectivity=1;

                wildernessNodes.push_back(wildNode);
                found=true;
            }
        }

        //Connect wilderness nodes to nearby places
        for(const PathNode& wildNode : wildernessNodes){
            if(pathId>=255) break;

            //Find the closest place node
            float closestDist=std::numeric_limits<float>::max();
            size_t closestIdx=0;

            for(size_t i=0; i<pathNodes.size(); i++){
                float dist=distanceBetweenPoints(wildNode.originX, wildNode.originY, pathNodes[i].originX, pathNodes[i].originY);
                if(dist<closestDist){
                    closestDist=dist;
                    closestIdx=i;
                }
            }

            //Generate path from this place to the wilderness node
            const PathNode& sourceNode=pathNodes[closestIdx];
            PathSegment segment;
            if(PathFinding::generatePath(
                mapData,
                sourceNode.originX, sourceNode.originY,
                wildNode.originX, wildNode.originY,
                pathId,
                segment
            )){
                pathData.push_back(segment);
                pathId++;
            }
        }
    }
}
