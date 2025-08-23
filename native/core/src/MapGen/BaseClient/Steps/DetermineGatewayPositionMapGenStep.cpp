#include "DetermineGatewayPositionMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cmath>

namespace ProceduralExplorationGameCore{

    DetermineGatewayPositionMapGenStep::DetermineGatewayPositionMapGenStep() : MapGenStep("Determine Gateway Position"){

    }

    DetermineGatewayPositionMapGenStep::~DetermineGatewayPositionMapGenStep(){

    }

    bool DetermineGatewayPositionMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const std::vector<FloodFillEntry*>& landData = (*mapData->ptr<std::vector<FloodFillEntry*>>("landData"));
        WorldPoint retPoint = INVALID_WORLD_POINT;

        for(int i = 0; i < 5; i++){
            LandId landId = findRandomLandmassForSize(landData, workspace->landWeighted, 40);
            if(landId == INVALID_LAND_ID){
                continue;
            }
            retPoint = findRandomPointInLandmass(landData[landId]);

            WorldCoord xx;
            WorldCoord yy;
            READ_WORLD_POINT(retPoint, xx, yy);

            WorldCoord px;
            WorldCoord py;
            READ_WORLD_POINT(mapData->worldPoint("playerStart"), px, py);

            float distance = sqrt(pow((float)px - (float)xx, 2) + pow((float)py - (float)yy, 2));
            if(distance > 200){
                break;
            }
        }

        if(retPoint == INVALID_WORLD_POINT){
            retPoint = WRAP_WORLD_POINT(mapData->width/2, mapData->height/2);
        }
        mapData->worldPoint("gatewayPosition", retPoint);

        return true;
    }

}
