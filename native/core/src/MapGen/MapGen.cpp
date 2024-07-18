#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "GameCoreLogger.h"

#include "MapGen/Steps/MapGenStep.h"
#include "MapGen/Steps/SetupBuffersMapGenStep.h"
#include "MapGen/Steps/GenerateNoiseMapGenStep.h"
#include "MapGen/Steps/ReduceNoiseMapGenStep.h"
#include "MapGen/Steps/PerformFloodFillMapGenStep.h"
#include "MapGen/Steps/RemoveRedundantIslandsMapGenStep.h"
#include "MapGen/Steps/WeightAndSortLandmassesMapGenStep.h"
#include "MapGen/Steps/DeterminePlayerStartMapGenStep.h"
#include "MapGen/Steps/DetermineGatewayPositionMapGenStep.h"
#include "MapGen/Steps/DetermineRegionsMapGenStep.h"
#include "MapGen/Steps/DetermineRegionTypesMapGenStep.h"
#include "MapGen/Steps/PopulateFinalBiomesMapGenStep.h"
#include "MapGen/Steps/DeterminePlacesMapGenStep.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    static const std::vector<std::pair<std::string, MapGenStep*>> MAP_GEN_STEPS = {
        {"Setup Buffers", new SetupBuffersMapGenStep()},
        {"Generate Noise", new GenerateNoiseMapGenStep()},
        {"Reduce Noise", new ReduceNoiseMapGenStep()},
        {"Perform Flood Fill", new PerformFloodFillMapGenStep()},
        {"Remove Redundant Islands", new RemoveRedundantIslandsMapGenStep()},
        {"Weight And Sort Landmasses", new WeightAndSortLandmassesMapGenStep()},
        {"Determine Player Start", new DeterminePlayerStartMapGenStep()},
        {"Determine Gateway Position", new DetermineGatewayPositionMapGenStep()},
        {"Determine Regions", new DetermineRegionsMapGenStep()},
        {"Determine Region Types", new DetermineRegionTypesMapGenStep()},
        {"Populate Final Biomes", new PopulateFinalBiomesMapGenStep()},
        {"Determine Places", new DeterminePlacesMapGenStep()},
    };

    MapGen::MapGen(){

    }

    MapGen::~MapGen(){

    }

    int MapGen::getCurrentStage() const{
        return mCurrentStage;
    }

    const std::string& MapGen::getNameForStage(int stage){
        return MAP_GEN_STEPS[stage].first;
    }

    void MapGen::beginMapGen(const ExplorationMapInputData* input){
        assert(!mMapData);
        mMapData = new ExplorationMapData();
        mMapInputData = input;
        std::thread* parentThread = new std::thread(&MapGen::beginMapGen_, this, input);
    }

    void MapGen::beginMapGen_(const ExplorationMapInputData* input){
        ExplorationMapGenWorkspace workspace;
        for(int i = 0; i < MAP_GEN_STEPS.size(); i++){
            AV::Timer t;
            t.start();
            MAP_GEN_STEPS[i].second->processStep(input, mMapData, &workspace);
            t.stop();
            GAME_CORE_INFO("Time taken for stage '{}' was {}", MAP_GEN_STEPS[i].first.c_str(), t.getTimeTotal());
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
        delete mMapInputData;
        ExplorationMapData* out = mMapData;
        mMapData = 0;
        return out;
    }
};
