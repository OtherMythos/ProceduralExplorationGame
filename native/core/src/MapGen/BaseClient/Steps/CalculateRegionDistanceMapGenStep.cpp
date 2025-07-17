#include "CalculateRegionDistanceMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "Util/MapGenDistance.h"

namespace ProceduralExplorationGameCore{

    CalculateRegionDistanceMapGenStep::CalculateRegionDistanceMapGenStep() : MapGenStep("Calculate Region Edges"){

    }

    CalculateRegionDistanceMapGenStep::~CalculateRegionDistanceMapGenStep(){

    }

    void CalculateRegionDistanceMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        CalculateRegionDistanceMapGenJob job;
        job.processJob(mapData, workspace);
    }



    CalculateRegionDistanceMapGenJob::CalculateRegionDistanceMapGenJob(){

    }

    CalculateRegionDistanceMapGenJob::~CalculateRegionDistanceMapGenJob(){

    }

    void CalculateRegionDistanceMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<AV::uint8> distances;
        distances.resize(mapData->width * mapData->height, 255);

        calculateRegionDistance(mapData, distances);

        for(AV::uint32 y = 0; y < mapData->height; y++){
            for(AV::uint32 x = 0; x < mapData->width; x++){
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
