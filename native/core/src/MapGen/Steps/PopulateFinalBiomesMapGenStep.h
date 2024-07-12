#pragma once

#include "MapGenStep.h"
#include <vector>
#include "GamePrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class PopulateFinalBiomesMapGenStep : public MapGenStep{
    public:
        PopulateFinalBiomesMapGenStep();
        ~PopulateFinalBiomesMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PopulateFinalBiomesMapGenJob{
    public:
        PopulateFinalBiomesMapGenJob();
        ~PopulateFinalBiomesMapGenJob();

        void processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb);

    };

}
