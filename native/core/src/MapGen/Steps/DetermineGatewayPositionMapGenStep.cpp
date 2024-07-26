#include "DetermineGatewayPositionMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cmath>

namespace ProceduralExplorationGameCore{

    DetermineGatewayPositionMapGenStep::DetermineGatewayPositionMapGenStep(){

    }

    DetermineGatewayPositionMapGenStep::~DetermineGatewayPositionMapGenStep(){

    }

    void DetermineGatewayPositionMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        WorldPoint retPoint = INVALID_WORLD_POINT;

        for(int i = 0; i < 5; i++){
            LandId landId = findRandomLandmassForSize(mapData->landData, workspace->landWeighted, 40);
            retPoint = findRandomPointInLandmass(mapData->landData[landId]);

            WorldCoord xx;
            WorldCoord yy;
            READ_WORLD_POINT(retPoint, xx, yy);

            WorldCoord px;
            WorldCoord py;
            READ_WORLD_POINT(mapData->playerStart, px, py);

            float distance = sqrt(pow((float)px - (float)xx, 2) + pow((float)py - (float)yy, 2));
            if(distance > 200){
                break;
            }
        }

        mapData->gatewayPosition = retPoint;
    }

}
