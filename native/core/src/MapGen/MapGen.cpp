#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/MapGenClient.h"
#include "MapGen/MapGenStep.h"
#include "MapGen/Script/ExplorationMapDataUserData.h"
#include "MapGen/BaseClient/MapGenBaseClient.h"
#include "GameCoreLogger.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    MapGen::MapGen()
        : mCurrentStage(0),
        mMapData(0),
        mCurrentCollectingMapGenClient(0) {

        //TODO move this elsewhere so it doesn't have to be used.
        registerMapGenClient("Base Client", new MapGenBaseClient());

        recollectMapGenSteps();
    }

    MapGen::~MapGen(){
        for(MapGenClient* c : mActiveClients){
            delete c;
        }
    }

    void MapGen::recollectMapGenSteps(){
        mMapGenSteps.clear();
        collectMapGenSteps_(mMapGenSteps);
    }

    int MapGen::getCurrentStage() const{
        return mCurrentStage;
    }

    std::string MapGen::getNameForStage(int stage){
        return mMapGenSteps[stage]->getName();
    }

    void MapGen::registerStep(int id, MapGenStep* mapGenStep){
        mMapGenSteps.insert(mMapGenSteps.begin() + id, mapGenStep);
    }

    void MapGen::collectMapGenSteps_(std::vector<MapGenStep*>& steps){
        for(MapGenClient* c : mActiveClients){
            mCurrentCollectingMapGenClient = c;
            c->populateSteps(steps);
        }
        mCurrentStage = mMapGenSteps.size();

        mCurrentCollectingMapGenClient = 0;
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

    void MapGen::notifyClientsClaimed_(HSQUIRRELVM vm, ExplorationMapData* data){
        for(MapGenClient* client : mActiveClients){
            const std::string& clientName = client->getName();

            sq_pushstring(vm, clientName.c_str(), -1);
            //sq_newtable(vm);
            bool objectPushed = client->notifyClaimed(vm, data);
            if(!objectPushed){
                //Remove the string object if we're not going to add to the table.
                sq_pop(vm, 1);
                continue;
            }
            sq_newslot(vm,-3,SQFalse);
        }

        //Push the map data
        sq_pushstring(vm, "data", -1);
        ExplorationMapDataUserData::ExplorationMapDataToUserData(vm, data);
        sq_newslot(vm, -3, SQFalse);
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

    void MapGen::registerMapGenClient(const std::string& clientName, MapGenClient* client, HSQUIRRELVM vm){
        mActiveClients.push_back(client);

        client->notifyRegistered(vm);
    }

    bool MapGen::claimMapData(HSQUIRRELVM vm){
        if(!isFinished()) return false;
        delete mMapInputData;
        mParentThread->join();
        delete mParentThread;
        ExplorationMapData* out = mMapData;
        mMapData = 0;

        sq_newtable(vm);
        notifyClientsClaimed_(vm, out);

        return true;
    }
};
