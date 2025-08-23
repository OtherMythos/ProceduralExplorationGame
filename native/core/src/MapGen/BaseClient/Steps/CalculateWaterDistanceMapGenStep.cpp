#include "CalculateWaterDistanceMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "Util/MapGenDistance.h"

namespace ProceduralExplorationGameCore{

    CalculateWaterDistanceMapGenStep::CalculateWaterDistanceMapGenStep() : MapGenStep("Calculate Water Distance"){

    }

    CalculateWaterDistanceMapGenStep::~CalculateWaterDistanceMapGenStep(){

    }

    bool CalculateWaterDistanceMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        CalculateWaterDistanceMapGenJob job;
        job.processJob(mapData, workspace);

        return true;
    }



    CalculateWaterDistanceMapGenJob::CalculateWaterDistanceMapGenJob(){

    }

    CalculateWaterDistanceMapGenJob::~CalculateWaterDistanceMapGenJob(){

    }

    void CalculateWaterDistanceMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<AV::uint8> distances;
        distances.resize(mapData->width * mapData->height, 255);

        calculateWaterDistance(mapData, distances);

        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
                if(*WATER_GROUP_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y)) == INVALID_WATER_ID){
                    //Only write to the water
                    continue;
                }

                AV::uint8 dist = distances[x + y * mapData->width];
                AV::uint8* distPtr = REGION_DISTANCE_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y));
                if(dist >= 254){
                    *distPtr = 0xFF;
                }else{
                    *distPtr = dist;
                }
            }
        }
    }
}
