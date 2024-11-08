#include "RemoveRedundantIslandsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    RemoveRedundantIslandsMapGenStep::RemoveRedundantIslandsMapGenStep(){

    }

    RemoveRedundantIslandsMapGenStep::~RemoveRedundantIslandsMapGenStep(){

    }

    void RemoveRedundantIslandsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        RemoveRedundantIslandsMapGenJob job;
        job.processJob(mapData, workspace);
    }



    RemoveRedundantIslandsMapGenJob::RemoveRedundantIslandsMapGenJob(){

    }

    RemoveRedundantIslandsMapGenJob::~RemoveRedundantIslandsMapGenJob(){

    }

    void RemoveRedundantIslandsMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        for(size_t i = 0; i < workspace->landData.size(); i++){
            FloodFillEntry* e = workspace->landData[i];
            //TODO separate this into the input data.
            if(e->total <= 30){
                //Iterate and set to be -1 sea level for all the coords.
                for(WorldPoint p : e->coords){
                    AV::uint8* vox = VOX_PTR_FOR_COORD(mapData, p);
                    *vox = static_cast<AV::uint8>(mapData->seaLevel) - 1;
                    //Mark as water
                    AV::uint8* landGroup = LAND_GROUP_PTR_FOR_COORD(mapData, p);
                    *landGroup = 0xFF;
                    AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD(mapData, p);
                    //TODO in future properly check this to prevent lake islands or anything like that being tagged as water.
                    //TODO remove the edges for the water groups now the land is removed.
                    *waterGroup = 0;
                }
                delete workspace->landData[i];
                workspace->landData[i] = 0;
            }
        }

        //Remove all the nulls from the list.
        auto it = workspace->landData.begin();
        while(it != workspace->landData.end()){
            if(*it == 0){
                it = workspace->landData.erase(it);
            }else it++;
        }
    }
}
