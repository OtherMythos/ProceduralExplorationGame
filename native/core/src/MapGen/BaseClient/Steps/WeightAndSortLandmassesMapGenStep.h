#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class WeightAndSortLandmassesMapGenStep : public MapGenStep{
    public:
        WeightAndSortLandmassesMapGenStep();
        ~WeightAndSortLandmassesMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
