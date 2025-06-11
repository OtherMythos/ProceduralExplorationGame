#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    class ExplorationMapData;

    class WeightAndSortLandmassesMapGenStep : public MapGenStep{
    public:
        WeightAndSortLandmassesMapGenStep();
        ~WeightAndSortLandmassesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
