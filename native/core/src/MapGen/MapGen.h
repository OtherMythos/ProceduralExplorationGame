#pragma once

#include <string>
#include <atomic>
#include <thread>
#include <vector>

#include "squirrel.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapData;
    class ExplorationMapInputData;

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
        void recollectMapGenSteps();
        void registerStep(int id, MapGenStep* mapGenStep);
        std::string getNameForStage(int stage);

        void registerMapGenClient(const std::string& clientName, MapGenClient* client);

        bool claimMapData(HSQUIRRELVM vm);

    private:
        std::atomic<int> mCurrentStage;
        std::thread* mParentThread;

        std::vector<MapGenClient*> mActiveClients;
        std::vector<MapGenStep*> mMapGenSteps;

        MapGenClient* mCurrentCollectingMapGenClient;

        ExplorationMapData* mMapData;
        const ExplorationMapInputData* mMapInputData;

        struct ThreadInput{
            const ExplorationMapInputData* input;
            const std::vector<MapGenStep*>* steps;
        };
        void beginMapGen_(const ThreadInput& input);
        void collectMapGenSteps_(std::vector<MapGenStep*>& steps);

        void notifyClientsBegan_(const ExplorationMapInputData* input);
        void notifyClientsEnded_(ExplorationMapData* data);
        void notifyClientsClaimed_(HSQUIRRELVM vm, ExplorationMapData* data);

    public:
        MapGenClient* getCurrentCollectingMapGenClient() { return mCurrentCollectingMapGenClient; }
    };

};
