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
        int registerStep(const std::string& markerName, MapGenStep* mapGenStep);
        std::string getNameForStage(int stage);
        bool _removeMarkerStep();
        void destroyMapData(ExplorationMapData* data);

        void registerMapGenClient(const std::string& clientName, MapGenClient* client, HSQUIRRELVM vm=0);

        bool claimMapData(HSQUIRRELVM vm);

    private:
        std::atomic<int> mCurrentStage;
        std::thread* mParentThread;

        std::vector<MapGenClient*> mActiveClients;
        std::vector<MapGenStep*> mMapGenSteps;

        MapGenClient* mCurrentCollectingMapGenClient;

        ExplorationMapData* mMapData;
        const ExplorationMapInputData* mMapInputData;
        int getIndexForMarker(const std::string& markerName);

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
