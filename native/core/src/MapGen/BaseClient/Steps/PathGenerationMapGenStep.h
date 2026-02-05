#pragma once

#include "MapGen/MapGenStep.h"

namespace ProceduralExplorationGameCore{

    class PathGenerationMapGenStep : public MapGenStep{
    public:
        PathGenerationMapGenStep();
        virtual ~PathGenerationMapGenStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);
    };
}
