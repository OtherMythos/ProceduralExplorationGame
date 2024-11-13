#include "MergeSmallRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    MergeSmallRegionsMapGenStep::MergeSmallRegionsMapGenStep(){

    }

    MergeSmallRegionsMapGenStep::~MergeSmallRegionsMapGenStep(){

    }

    inline RegionId _checkRegion(ExplorationMapData* data, WorldPoint p){
        return *REGION_PTR_FOR_COORD_CONST(data, p);
    }
    void MergeSmallRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        for(RegionData& d : mapData->regionData){
            if(d.total >= 200) continue;

            //Go through the edges and check the neighbours for a region
            std::set<RegionId> foundRegions;
            for(WorldPoint p : d.edges){
                WorldCoord xp, yp;
                READ_WORLD_POINT(p, xp, yp);

                foundRegions.insert(_checkRegion(mapData, WRAP_WORLD_POINT(xp + 1, yp)));
                foundRegions.insert(_checkRegion(mapData, WRAP_WORLD_POINT(xp - 1, yp)));
                foundRegions.insert(_checkRegion(mapData, WRAP_WORLD_POINT(xp, yp + 1)));
                foundRegions.insert(_checkRegion(mapData, WRAP_WORLD_POINT(xp, yp - 1)));
            }

            for(RegionId r : foundRegions){
                //TODO do I need this?
                if(r == 0x0) continue;
                RegionData& sd = mapData->regionData[r];
                d.total = 0;
                sd.coords.insert(sd.coords.end(), d.coords.begin(), d.coords.end());

                for(WorldPoint wp : d.coords){
                    RegionId* writeRegion = REGION_PTR_FOR_COORD(mapData, wp);
                    *writeRegion = sd.id;
                }

                //Just take the first value for now.
                break;
            }
        }
    }

}
