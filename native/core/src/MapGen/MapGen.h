#pragma once

#include <string>
#include <atomic>
#include <thread>
#include <vector>

namespace ProceduralExplorationGameCore{

    struct ExplorationMapData;
    struct ExplorationMapInputData;

    class MapGenClient;
    class MapGenStep;

    class MapGen{
    public:
        MapGen();
        ~MapGen();

        int getCurrentStage() const;
        bool isFinished() const;
        void beginMapGen(const ExplorationMapInputData* input);
        int getNumTotalStages();
        std::string getNameForStage(int stage);

        void registerMapGenClient(const std::string& clientName, MapGenClient* client);

        ExplorationMapData* claimMapData();

    private:
        std::atomic<int> mCurrentStage;
        std::thread* mParentThread;

        std::vector<MapGenClient*> mActiveClients;
        std::vector<MapGenStep*> mMapGenSteps;

        ExplorationMapData* mMapData;
        const ExplorationMapInputData* mMapInputData;

        void beginMapGen_(const ExplorationMapInputData* input, const std::vector<MapGenStep*>& steps);
        void collectMapGenSteps_(std::vector<MapGenStep*>& steps);
    };

};
