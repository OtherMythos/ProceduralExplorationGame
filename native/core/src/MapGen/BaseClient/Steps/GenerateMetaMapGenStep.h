#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;

    class GenerateMetaMapGenStep : public MapGenStep{
    public:
        GenerateMetaMapGenStep();
        ~GenerateMetaMapGenStep();

        bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace) override;
    };

}
