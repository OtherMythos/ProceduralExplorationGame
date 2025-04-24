#pragma once

#include "MapGenClient.h"
#include <vector>

#include "MapGen/MapGenStep.h"

namespace AV{
    class CallbackScript;
}

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    class CallbackScript;
    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class MapGenScriptStep : public MapGenStep{
    public:
        MapGenScriptStep(const std::string& stepName);
        ~MapGenScriptStep();

        virtual void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);
    };
}
