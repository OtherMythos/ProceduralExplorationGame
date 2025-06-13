#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class DetermineGatewayPositionMapGenStep : public MapGenStep{
    public:
        DetermineGatewayPositionMapGenStep();
        ~DetermineGatewayPositionMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
