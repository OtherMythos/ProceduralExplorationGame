#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class ReduceNoiseMapGenStep : public MapGenStep{
    public:
        ReduceNoiseMapGenStep();
        ~ReduceNoiseMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData) override;
    };

    class ReduceNoiseMapGenJob{
    public:
        ReduceNoiseMapGenJob();
        ~ReduceNoiseMapGenJob();

        void processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb);

    };

}
