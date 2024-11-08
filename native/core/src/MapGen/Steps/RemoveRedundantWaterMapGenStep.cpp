#include "RemoveRedundantWaterMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    RemoveRedundantWaterMapGenStep::RemoveRedundantWaterMapGenStep(){

    }

    RemoveRedundantWaterMapGenStep::~RemoveRedundantWaterMapGenStep(){

    }

    void RemoveRedundantWaterMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        RemoveRedundantWaterMapGenJob job;
        job.processJob(mapData, workspace);
    }



    RemoveRedundantWaterMapGenJob::RemoveRedundantWaterMapGenJob(){

    }

    RemoveRedundantWaterMapGenJob::~RemoveRedundantWaterMapGenJob(){

    }

    void RemoveRedundantWaterMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        for(size_t i = 0; i < workspace->waterData.size(); i++){
            FloodFillEntry* e = workspace->waterData[i];
            //TODO separate this into the input data.
            if(e->total <= 100){
                //Iterate and set to be -1 sea level for all the coords.
                for(WorldPoint p : e->coords){
                    AV::uint8* vox = VOX_PTR_FOR_COORD(mapData, p);
                    *vox = static_cast<AV::uint8>(mapData->seaLevel);
                }
                delete workspace->waterData[i];
                workspace->waterData[i] = 0;
            }
        }

        //Remove all the nulls from the list.
        auto it = workspace->waterData.begin();
        while(it != workspace->waterData.end()){
            if(*it == 0){
                it = workspace->waterData.erase(it);
            }else it++;
        }
    }
}
