#pragma once

#include "MapGenClient.h"
#include <squirrel.h>
#include <vector>

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    class CallbackScript;
    class ExplorationMapInputData;
    class ExplorationMapData;

    class MapGenScriptClient : public MapGenClient{
    public:
        MapGenScriptClient(CallbackScript* script, const std::string& name);
        ~MapGenScriptClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);

        virtual void notifyBegan(const ExplorationMapInputData* input);
        virtual void notifyEnded(ExplorationMapData* mapData);
        virtual bool notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData);
        virtual void notifyRegistered(HSQUIRRELVM vm);

    private:
        CallbackScript* mScript;
        SQObject mClientTableObj;

    public:
        SQObject getClientTable() { return mClientTableObj; }
    };
}
