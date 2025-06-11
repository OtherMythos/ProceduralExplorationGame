#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class PerformFinalFloodFillMapGenStep : public MapGenStep{
    public:
        PerformFinalFloodFillMapGenStep();
        ~PerformFinalFloodFillMapGenStep();

        void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PerformFinalFloodFillMapGenJob{
    public:
        PerformFinalFloodFillMapGenJob();
        ~PerformFinalFloodFillMapGenJob();

        void processJob(ExplorationMapData* mapData);

    private:
        static inline bool comparisonFuncLand(ExplorationMapData* mapData, AV::uint8 val);
        static inline AV::uint8 readFuncAltitude(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y);
        static inline bool comparisonFuncWater(ExplorationMapData* mapData, AV::uint8 val);

    };

}
