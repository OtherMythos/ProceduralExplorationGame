#pragma once

#include "MapGen/MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class BiomeFinalChangesMapGenStep : public MapGenStep{
    public:
        BiomeFinalChangesMapGenStep();
        ~BiomeFinalChangesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class BiomeFinalChangesMapGenJob{
    public:
        BiomeFinalChangesMapGenJob();
        ~BiomeFinalChangesMapGenJob();

        void processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb);

    };

}
