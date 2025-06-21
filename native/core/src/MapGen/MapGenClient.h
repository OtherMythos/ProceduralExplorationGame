#pragma once

#include <vector>
#include <string>
#include "squirrel.h"

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    class ExplorationMapInputData;
    class ExplorationMapData;

    class MapGenClient{
    public:
        MapGenClient(const std::string& name);
        ~MapGenClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);

        //Called at the very beginning of map gen, on the worker thread
        virtual void notifyBegan(const ExplorationMapInputData* input);
        virtual void notifyEnded(ExplorationMapData* mapData);
        virtual bool notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData);
        virtual void notifyRegistered(HSQUIRRELVM vm);

    private:
        std::string mName;

    public:
        const std::string& getName() const { return mName; }
    };
}
