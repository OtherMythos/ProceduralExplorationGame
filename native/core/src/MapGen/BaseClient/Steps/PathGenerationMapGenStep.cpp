#include "PathGenerationMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/PathFinding/PathFinding.h"

#include <cmath>
#include <algorithm>
#include <string>
#include <vector>
#include <set>

namespace ProceduralExplorationGameCore{

    PathGenerationMapGenStep::PathGenerationMapGenStep() : MapGenStep("Path Generation"){
    }

    PathGenerationMapGenStep::~PathGenerationMapGenStep(){
    }

    struct PathNode{
        WorldCoord originX, originY;
        RegionId region;
        AV::uint8 pathSpawns;
        bool canReceivePaths;
        AV::uint8 connectivity;
    };

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

        return true;
    }
}
