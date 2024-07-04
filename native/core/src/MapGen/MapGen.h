#pragma once

#include <atomic>
#include <thread>

namespace ProceduralExplorationGameCore{

    class MapGen{
    public:
        MapGen();
        ~MapGen();

        int getCurrentStage() const;
        bool isFinished() const;
        void beginMapGen();
        static int getNumTotalStages();

    private:
        std::atomic<int> mCurrentStage;
        std::thread* parentThread;

        void beginMapGen_();
    };

};