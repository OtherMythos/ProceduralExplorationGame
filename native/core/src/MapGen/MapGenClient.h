#pragma once

#include <vector>

namespace ProceduralExplorationGameCore{
    class MapGenStep;

    class MapGenClient{
    public:
        MapGenClient();
        ~MapGenClient();

        virtual void populateSteps(std::vector<MapGenStep*>& steps);
    };
}
