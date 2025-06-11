#pragma once

#include <vector>

namespace ProceduralExplorationGameCore{
    class MapGenStep;
    struct ExplorationMapInputData;
    class ExplorationMapData;

    class MapGenClient{
    public:
        MapGenClient();
        ~MapGenClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);

        //Called at the very beginning of map gen, on the worker thread
        virtual void notifyBegan(const ExplorationMapInputData* input);
        virtual void notifyEnded(ExplorationMapData* mapData);
        virtual void notifyClaimed(ExplorationMapData* mapData);
    };
}
