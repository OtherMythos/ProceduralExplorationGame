#pragma once

#include "MapGen/MapGenStep.h"

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class PerformPreFloodFillMapGenStep : public MapGenStep{
    public:
        PerformPreFloodFillMapGenStep();
        ~PerformPreFloodFillMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

    class PerformPreFloodFillMapGenJob{
    public:
        PerformPreFloodFillMapGenJob();
        ~PerformPreFloodFillMapGenJob();

        void processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

        static bool comparisonFuncLand(ExplorationMapData* mapData, AV::uint8 val);
        static AV::uint8 readFuncAltitude(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y);
        static bool comparisonFuncWater(ExplorationMapData* mapData, AV::uint8 val);


    };

}
