#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/MapGenClient.h"
//TODO move the base out of the steps class.
#include "MapGen/Steps/MapGenStep.h"
#include "MapGen/BaseClient/MapGenBaseClient.h"
#include "GameCoreLogger.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    MapGen::MapGen()
        : mCurrentStage(0),
        mMapData(0) {

        //TODO move this elsewhere so it doesn't have to be used.
        registerMapGenClient("Base Client", new MapGenBaseClient());

        mMapGenSteps.clear();
        collectMapGenSteps_(mMapGenSteps);

    }

    MapGen::~MapGen(){
        for(MapGenClient* c : mActiveClients){
            delete c;
        }
    }

    int MapGen::getCurrentStage() const{
        return mCurrentStage;
    }

    std::string MapGen::getNameForStage(int stage){
        return mMapGenSteps[stage]->getName();
    }

    void MapGen::collectMapGenSteps_(std::vector<MapGenStep*>& steps){
        for(MapGenClient* c : mActiveClients){
            c->populateSteps(steps);
        }
        mCurrentStage = mMapGenSteps.size();
    }

    void MapGen::beginMapGen(const ExplorationMapInputData* input){
        assert(!mMapData);

        mMapData = new ExplorationMapData();
        mMapInputData = input;
        ThreadInput i;
        i.input = input;
        i.steps = &mMapGenSteps;
        mCurrentStage = 0;
        mParentThread = new std::thread(&MapGen::beginMapGen_, this, i);
    }

    void MapGen::notifyClientsBegan_(const ExplorationMapInputData* input){
        for(MapGenClient* client : mActiveClients){
            client->notifyBegan(input);
        }
    }

    void MapGen::notifyClientsEnded_(ExplorationMapData* data){
        for(MapGenClient* client : mActiveClients){
            client->notifyEnded(data);
        }
    }

    void MapGen::notifyClientsClaimed_(ExplorationMapData* data){
        for(MapGenClient* client : mActiveClients){
            client->notifyClaimed(data);
        }
    }

    void MapGen::beginMapGen_(const ThreadInput& input){
        AV::Timer tt;
        tt.start();
        notifyClientsBegan_(input.input);
        ExplorationMapGenWorkspace workspace;
        const std::vector<MapGenStep*>& steps = *(input.steps);
        for(int i = 0; i < steps.size(); i++){
            AV::Timer t;
            t.start();
            steps[i]->processStep(input.input, mMapData, &workspace);
            t.stop();
            GAME_CORE_INFO("Time taken for stage '{}' was {}", steps[i]->getName(), t.getTimeTotal());
            mCurrentStage++;
        }
        notifyClientsEnded_(mMapData);
        tt.stop();
        GAME_CORE_INFO("Total time for map gen was {}", tt.getTimeTotal());
    }

    int MapGen::getNumTotalStages(){
        return static_cast<int>(mMapGenSteps.size());
    }

    bool MapGen::isFinished() const{
        return mCurrentStage >= mMapGenSteps.size();
    };

    void MapGen::registerMapGenClient(const std::string& clientName, MapGenClient* client){
        mActiveClients.push_back(client);
    }

    ExplorationMapData* MapGen::claimMapData(){
        if(!isFinished()) return 0;
        delete mMapInputData;
        mParentThread->join();
        delete mParentThread;
        ExplorationMapData* out = mMapData;
        mMapData = 0;

        notifyClientsClaimed_(out);

        return out;
    }
};
