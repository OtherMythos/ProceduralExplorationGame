#pragma once

#include <atomic>
#include <thread>

namespace ProceduralExplorationGameCore{

    struct ExplorationMapData;
    struct ExplorationMapInputData;

    class MapGen{
    public:
        MapGen();
        ~MapGen();

        int getCurrentStage() const;
        bool isFinished() const;
        void beginMapGen(const ExplorationMapInputData* input);
        static int getNumTotalStages();
        static const std::string& getNameForStage(int stage);

        ExplorationMapData* claimMapData();

    private:
        std::atomic<int> mCurrentStage;
        std::thread* parentThread;

        ExplorationMapData* mMapData;

        void beginMapGen_(const ExplorationMapInputData* input);
    };

};
