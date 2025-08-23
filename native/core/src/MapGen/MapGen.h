#pragma once

#include "System/EnginePrerequisites.h"

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
    struct ExplorationMapGenWorkspace;

    class MapGen{
    public:
        MapGen();
        ~MapGen();

        typedef AV::uint8 VoxelId;
        struct VoxelDef{
            AV::uint8 vId;
            AV::uint32 colourABGR;
        };

        int getCurrentStage() const;
        bool isFinished() const;
        bool hasFailed() const;
        void beginMapGen(const ExplorationMapInputData* input);
        int getNumTotalStages();
        void recollectMapGenSteps();
        void registerStep(int id, MapGenStep* mapGenStep);
        int registerStep(const std::string& markerName, MapGenStep* mapGenStep);
        std::string getNameForStage(int stage);
        bool _removeMarkerStep();
        void destroyMapData(ExplorationMapData* data);

        void registerMapGenClient(const std::string& clientName, MapGenClient* client, HSQUIRRELVM vm=0);

        void registerVoxel(VoxelId v, AV::uint8 id, AV::uint32 colourABGR);

        bool claimMapData(HSQUIRRELVM vm);

    private:
        std::atomic<int> mCurrentStage;
        std::atomic<bool> mFailed;
        std::thread* mParentThread;

        std::vector<MapGenClient*> mActiveClients;
        std::vector<MapGenStep*> mMapGenSteps;
        std::vector<VoxelDef> mVoxelDef;

        MapGenClient* mCurrentCollectingMapGenClient;

        ExplorationMapData* mMapData;
        const ExplorationMapInputData* mMapInputData;
        int getIndexForMarker(const std::string& markerName);

        void _destroyMapGenSteps();

        struct ThreadInput{
            const ExplorationMapInputData* input;
            const std::vector<MapGenStep*>* steps;
        };
        void beginMapGen_(const ThreadInput& input);
        void collectMapGenSteps_(std::vector<MapGenStep*>& steps);

        void notifyClientsBegan_(const ExplorationMapInputData* input);
        void notifyClientsEnded_(ExplorationMapData* data, ExplorationMapGenWorkspace* workspace);
        void notifyClientsClaimed_(HSQUIRRELVM vm, ExplorationMapData* data);

    public:
        MapGenClient* getCurrentCollectingMapGenClient() { return mCurrentCollectingMapGenClient; }

        const std::vector<VoxelDef>& getVoxelDefs() const { return mVoxelDef; }
    };

};
