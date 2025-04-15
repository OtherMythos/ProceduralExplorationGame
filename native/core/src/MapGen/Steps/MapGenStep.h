#pragma once

#include <string>

namespace ProceduralExplorationGameCore{

    struct ExplorationMapInputData;
    struct ExplorationMapData;
    struct ExplorationMapGenWorkspace;

    class MapGenStep{
    public:
        MapGenStep(const std::string& name);
        ~MapGenStep();

        virtual void processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

        std::string getName() const;

    private:
        std::string mName;
    };

}
