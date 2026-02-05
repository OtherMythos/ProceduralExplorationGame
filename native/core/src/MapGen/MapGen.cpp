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

        mVoxelDef.resize(MAX_VOXELS);
    }

    MapGen::~MapGen(){
        _destroyMapGenSteps();
        for(MapGenClient* c : mActiveClients){
            delete c;
        }
    }

    void MapGen::_destroyMapGenSteps(){
        for(MapGenStep* s : mMapGenSteps){
            delete s;
        }
        mMapGenSteps.clear();
    }

    void MapGen::recollectMapGenSteps(){
        _destroyMapGenSteps();
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
        mCurrentStage = mMapGenSteps.size();
    }

    int MapGen::registerStep(const std::string& markerName, MapGenStep* mapGenStep){
        int step = getIndexForMarker(markerName);
        registerStep(step, mapGenStep);
        return step;
    }

    bool MapGen::_removeMarkerStep(){
        auto it = mMapGenSteps.begin();
        while(it != mMapGenSteps.end()){
            if((*it)->isMarkerStep()){
                delete *it;
                mMapGenSteps.erase(it);
                return false;
            }
            it++;
        }
        return true;
    }

    void MapGen::collectMapGenSteps_(std::vector<MapGenStep*>& steps){
        for(MapGenClient* c : mActiveClients){
            mCurrentCollectingMapGenClient = c;
            c->populateSteps(steps);

            mCurrentStage = mMapGenSteps.size();
        }

        //Remove all the markers from the steps.
        while(true){
            if(_removeMarkerStep()){
                break;
            }
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
        mFailed = false;
        mParentThread = new std::thread(&MapGen::beginMapGen_, this, i);
    }

    void MapGen::notifyClientsBegan_(const ExplorationMapInputData* input){
        for(MapGenClient* client : mActiveClients){
            client->notifyBegan(input);
        }
    }

    void MapGen::notifyClientsEnded_(ExplorationMapData* data, ExplorationMapGenWorkspace* workspace){
        for(MapGenClient* client : mActiveClients){
            client->notifyEnded(data, workspace);
        }
    }

    int MapGen::getIndexForMarker(const std::string& markerName){
        const std::string checkName = "Marker-" + markerName;
        int idx = 0;
        for(MapGenStep* s : mMapGenSteps){
            if(s->getName() == checkName){
                return idx;
            }
            idx++;
        }
        return idx;
    }

    void MapGen::destroyMapData(ExplorationMapData* data){
        for(MapGenClient* c : mActiveClients){
            c->destroyMapData(data);
        }

        delete data;
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
        ExplorationMapDataUserData::ExplorationMapDataToUserData<false>(vm, data);
        sq_newslot(vm, -3, SQFalse);
    }

    void MapGen::beginMapGen_(const ThreadInput& input){
        AV::Timer tt;
        tt.start();
        notifyClientsBegan_(input.input);
        ExplorationMapGenWorkspace workspace;
        const std::vector<MapGenStep*>& steps = *(input.steps);
        bool success = true;
        for(int i = 0; i < steps.size(); i++){
            AV::Timer t;
            t.start();
            success = steps[i]->processStep(input.input, mMapData, &workspace);
            t.stop();
            if(!success){
                break;
            }
            GAME_CORE_INFO("Time taken for stage '{}' was {}", steps[i]->getName(), t.getTimeTotal());
            mCurrentStage++;
        }
        if(!success){
            GAME_CORE_ERROR("Map Gen failed!");
            mFailed = true;
        }
        notifyClientsEnded_(mMapData, &workspace);
        tt.stop();
        GAME_CORE_INFO("Total time for map gen was {}", tt.getTimeTotal());
    }

    int MapGen::getNumTotalStages(){
        return static_cast<int>(mMapGenSteps.size());
    }

    void MapGen::registerVoxel(VoxelId v, AV::uint8 id, AV::uint32 colourABGR){
        mVoxelDef[v] = {id, colourABGR};
    }

    bool MapGen::isFinished() const{
        return mCurrentStage >= mMapGenSteps.size();
    };

    bool MapGen::hasFailed() const{
        return mFailed;
    }

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
