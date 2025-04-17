#pragma once

#include "MapGenClient.h"
#include <vector>

namespace AV{
    class CallbackScript;
}

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    class CallbackScript;
    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class MapGenScriptClient : public MapGenClient{
    public:
        MapGenScriptClient(CallbackScript* script);
        ~MapGenScriptClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);

        virtual void notifyBegan(const ExplorationMapInputData* input);
        virtual void notifyEnded(ExplorationMapData* mapData);
        virtual void notifyClaimed(ExplorationMapData* mapData);

    private:
        CallbackScript* mScript;
    };
}
