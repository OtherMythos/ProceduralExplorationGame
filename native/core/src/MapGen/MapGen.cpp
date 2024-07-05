#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "MapGen/Steps/MapGenStep.h"
#include "MapGen/Steps/SetupBuffersMapGenStep.h"
#include "MapGen/Steps/GenerateNoiseMapGenStep.h"
#include "MapGen/Steps/ReduceNoiseMapGenStep.h"

namespace ProceduralExplorationGameCore{

    static const std::vector<std::pair<std::string, MapGenStep*>> MAP_GEN_STEPS = {
        {"Setup Buffers", new SetupBuffersMapGenStep()},
        {"Generate Noise", new GenerateNoiseMapGenStep()},
        {"Reduce Noise", new ReduceNoiseMapGenStep()},
        //{"Altitiude", new MapGenStep()},
    };

    MapGen::MapGen(){

    }

    MapGen::~MapGen(){

    }

    int MapGen::getCurrentStage() const{
        return mCurrentStage;
    }

    void MapGen::beginMapGen(const ExplorationMapInputData* input){
        assert(!mMapData);
        mMapData = new ExplorationMapData();
        std::thread* parentThread = new std::thread(&MapGen::beginMapGen_, this, input);
    }

    void MapGen::beginMapGen_(const ExplorationMapInputData* input){
        for(int i = 0; i < MAP_GEN_STEPS.size(); i++){
            MAP_GEN_STEPS[i].second->processStep(input, mMapData);
            mCurrentStage++;
        }
    }

    int MapGen::getNumTotalStages(){
        return static_cast<int>(MAP_GEN_STEPS.size());
    }

    bool MapGen::isFinished() const{
        return mCurrentStage >= MAP_GEN_STEPS.size();
    };

    ExplorationMapData* MapGen::claimMapData(){
        if(!isFinished()) return 0;
        ExplorationMapData* out = mMapData;
        mMapData = 0;
        return out;
    }
};
