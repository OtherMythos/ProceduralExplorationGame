#pragma once

#include <string>

namespace ProceduralExplorationGameCore{

    class ExplorationMapInputData;
    class ExplorationMapData;
    struct ExplorationMapGenWorkspace;

    class MapGenStep{
    public:
        MapGenStep(const std::string& name);
        ~MapGenStep();

        virtual bool processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace);

        std::string getName() const;

    private:
        std::string mName;

    protected:
        bool mMarkerStep;

    public:
        bool isMarkerStep() const { return mMarkerStep; }
    };

}
