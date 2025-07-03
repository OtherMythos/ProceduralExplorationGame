#pragma once

#include "MapGen/MapGenClient.h"

#include <vector>

namespace ProceduralExplorationGameCore{
    class MapGenStep;

    class MapGenBaseClient : public MapGenClient{
    public:
        MapGenBaseClient();
        ~MapGenBaseClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps) override;

        virtual bool notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData) override;
        virtual void destroyMapData(ExplorationMapData* mapData);
    };
}
