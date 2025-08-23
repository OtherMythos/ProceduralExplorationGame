#include "RecalculateRegionEdgesMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <array>

namespace ProceduralExplorationGameCore{

    RecalculateRegionEdgesMapGenStep::RecalculateRegionEdgesMapGenStep() : MapGenStep("Determine Region Types"){

    }

    RecalculateRegionEdgesMapGenStep::~RecalculateRegionEdgesMapGenStep(){

    }

    bool RecalculateRegionEdgesMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        for(RegionData& r : regionData){
            r.edges.clear();
            for(WorldPoint p : r.coords){
                WorldCoord x, y;
                READ_WORLD_POINT(p, x, y);
                std::vector<WorldPoint> neighbors = {
                    WRAP_WORLD_POINT(x + 1, y),
                    WRAP_WORLD_POINT(x - 1, y),
                    WRAP_WORLD_POINT(x, y + 1),
                    WRAP_WORLD_POINT(x, y - 1)
                };

                bool same = true;
                for(WorldPoint checkPoint : neighbors){
                    const RegionId* region = REGION_PTR_FOR_COORD_CONST(mapData, checkPoint);
                    if(*region != r.id){
                        same = false;
                        break;
                    }
                }
                if(!same){
                    r.edges.push_back(p);
                }
            }

        }

        return true;
    }

}
