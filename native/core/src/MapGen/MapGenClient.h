#pragma once

#include <vector>
#include <string>
#include "squirrel.h"

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    class ExplorationMapInputData;
    class ExplorationMapData;
    struct ExplorationMapGenWorkspace;

    class MapGenClient{
    public:
        MapGenClient(const std::string& name);
        ~MapGenClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);

        //Called at the very beginning of map gen, on the worker thread
        virtual void notifyBegan(const ExplorationMapInputData* input);
        virtual void notifyEnded(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);
        virtual bool notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData);
        virtual void notifyRegistered(HSQUIRRELVM vm);
        virtual void destroyMapData(ExplorationMapData* mapData);

    private:
        std::string mName;

    public:
        const std::string& getName() const { return mName; }
    };
}
