#include "MergeIsolatedRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    MergeIsolatedRegionsMapGenStep::MergeIsolatedRegionsMapGenStep(){

    }

    MergeIsolatedRegionsMapGenStep::~MergeIsolatedRegionsMapGenStep(){

    }

    void _orderSmallest(RegionData& f, RegionData& s, RegionData** biggest, RegionData** smallest){
        if(f.total >= s.total){
            *biggest = &f;
            *smallest = &s;
        }else{
            *smallest = &f;
            *biggest = &s;
        }
    }

    void MergeIsolatedRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        auto it = mapData->regionData.begin();
        //for(RegionData& d : mapData->regionData){
        for(int i = 0; i < mapData->regionData.size(); i++){
            RegionData& d = mapData->regionData[i];
            //if(d.total >= 400 || d.total == 0) continue;
            if(d.total == 0) continue;

            //Go through the edges and check the neighbours for a region
            std::set<RegionId> foundRegions;
            findNeighboursForRegion(mapData, d, foundRegions);

            auto it = foundRegions.find(0x0);
            if(it != foundRegions.end()){
                foundRegions.erase(it);
            }
            it = foundRegions.find(d.id);
            if(it != foundRegions.end()){
                foundRegions.erase(it);
            }

            it = foundRegions.begin();
            while(it != foundRegions.end()){
                if(mapData->regionData[*it].total == 0){
                    foundRegions.erase(it);
                    it = foundRegions.begin();
                }
                else it++;
            }

            //The region only has the one neighbour, so figure out which is the biggest and merge into that.
            if(foundRegions.size() != 1) continue;

            RegionData* biggest;
            RegionData* smallest;
            _orderSmallest(d, mapData->regionData[*(foundRegions.begin())], &biggest, &smallest);
            //Incase it stumbles upon coordinates which have already been merged
            if(smallest->total == 0 || biggest->total == 0) continue;
            assert(biggest->total >= smallest->total);

            if(
               smallest->meta & static_cast<AV::uint8>(RegionMeta::MAIN_REGION) &&
               !(biggest->meta & static_cast<AV::uint8>(RegionMeta::MAIN_REGION))
            ){
                //Flip the regions to ensure a main region is not absorbed.
                RegionData* flip = smallest;
                smallest = biggest;
                biggest = flip;
            }

            mergeRegionData(mapData, *smallest, *biggest);

            //Reset the search now something has changed;
            i = 0;

            //Merge the layer
        }
    }

}
