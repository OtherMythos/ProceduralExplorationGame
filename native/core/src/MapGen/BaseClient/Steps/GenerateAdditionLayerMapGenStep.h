#pragma once

#include "MapGen/MapGenStep.h"

#include "GamePrerequisites.h"
#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateAdditionLayerMapGenStep : public MapGenStep{
    public:
        GenerateAdditionLayerMapGenStep();
        ~GenerateAdditionLayerMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
