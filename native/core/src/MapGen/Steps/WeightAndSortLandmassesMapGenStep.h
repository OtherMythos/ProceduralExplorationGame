#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class WeightAndSortLandmassesMapGenStep : public MapGenStep{
    public:
        WeightAndSortLandmassesMapGenStep();
        ~WeightAndSortLandmassesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
