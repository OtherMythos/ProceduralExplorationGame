#pragma once

#include <atomic>
#include <thread>
#include <string>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;

    class VisitedPlacesParser{
    public:
        VisitedPlacesParser();
        ~VisitedPlacesParser();

        int getCurrentStage() const;
        void beginMapGen(const std::string& mapName);
        bool isFinished() const;
        VisitedPlaceMapData* claimMapData();

        static std::string mMapsDirectory;

    private:
        std::atomic<int> mCurrentStage;
        std::thread* mParentThread;

        VisitedPlaceMapData* mMapData;

        void beginMapGen_(const std::string& mapName);
    };

}
