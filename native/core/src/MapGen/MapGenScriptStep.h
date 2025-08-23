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
    class ExplorationMapInputData;
    class MapGenScriptClient;
    class ExplorationMapData;

    class MapGenScriptStep : public MapGenStep{
    public:
        MapGenScriptStep(const std::string& stepName, MapGenScriptClient* parentClient, CallbackScript* script);
        ~MapGenScriptStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

    private:
        CallbackScript* mScript;
        MapGenScriptClient* mParentClient;
    };

}
