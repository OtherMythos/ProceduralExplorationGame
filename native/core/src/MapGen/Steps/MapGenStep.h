#pragma once

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;

    class MapGenStep{
    public:
        MapGenStep();
        ~MapGenStep();

        virtual void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData);
    };

}