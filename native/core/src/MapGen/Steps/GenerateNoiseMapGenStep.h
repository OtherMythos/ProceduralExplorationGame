#pragma once

#include "MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class GenerateNoiseMapGenStep : public MapGenStep{
    public:
        GenerateNoiseMapGenStep();
        ~GenerateNoiseMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class GenerateNoiseMapGenJob{
    public:
        GenerateNoiseMapGenJob();
        ~GenerateNoiseMapGenJob();

        void processJob(ExplorationMapData* mapData, AV::uint32 xa, AV::uint32 ya, AV::uint32 xb, AV::uint32 yb);

    };

}
