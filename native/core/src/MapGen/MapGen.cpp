#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "GameCoreLogger.h"

#include "MapGen/Steps/MapGenStep.h"
#include "MapGen/Steps/GenerateMetaMapGenStep.h"
#include "MapGen/Steps/SetupBuffersMapGenStep.h"
#include "MapGen/Steps/GenerateNoiseMapGenStep.h"
#include "MapGen/Steps/GenerateAdditionLayerMapGenStep.h"
#include "MapGen/Steps/MergeAltitudeMapGenStep.h"
#include "MapGen/Steps/ReduceNoiseMapGenStep.h"
#include "MapGen/Steps/PerformFinalFloodFillMapGenStep.h"
#include "MapGen/Steps/PerformPreFloodFillMapGenStep.h"
#include "MapGen/Steps/RemoveRedundantIslandsMapGenStep.h"
#include "MapGen/Steps/RemoveRedundantWaterMapGenStep.h"
#include "MapGen/Steps/IsolateRegionsMapGenStep.h"
#include "MapGen/Steps/WeightAndSortLandmassesMapGenStep.h"
#include "MapGen/Steps/DetermineEarlyRegionsMapGenStep.h"
#include "MapGen/Steps/DetermineEdgesMapGenStep.h"
#include "MapGen/Steps/DetermineRiversMapGenStep.h"
#include "MapGen/Steps/CarveRiversMapGenStep.h"
#include "MapGen/Steps/DeterminePlayerStartMapGenStep.h"
#include "MapGen/Steps/DetermineGatewayPositionMapGenStep.h"
#include "MapGen/Steps/DetermineRegionsMapGenStep.h"
#include "MapGen/Steps/DetermineRegionTypesMapGenStep.h"
#include "MapGen/Steps/PopulateFinalBiomesMapGenStep.h"
#include "MapGen/Steps/DeterminePlacesMapGenStep.h"
#include "MapGen/Steps/MergeSmallRegionsMapGenStep.h"

#include "System/Util/Timer/Timer.h"

namespace ProceduralExplorationGameCore{

    static const std::vector<std::pair<std::string, MapGenStep*>> MAP_GEN_STEPS = {
        {"Generate Meta", new GenerateMetaMapGenStep()},
        {"Setup Buffers", new SetupBuffersMapGenStep()},
        {"Generate Noise", new GenerateNoiseMapGenStep()},
        {"Generate Addition Layer", new GenerateAdditionLayerMapGenStep()},
        {"Merge Altitude", new MergeAltitudeMapGenStep()},
        {"Reduce Noise", new ReduceNoiseMapGenStep()},
        {"Perform Pre Flood Fill", new PerformPreFloodFillMapGenStep()},
        {"Remove Redundant Islands", new RemoveRedundantIslandsMapGenStep()},
        {"Remove Redundant Water", new RemoveRedundantWaterMapGenStep()},
        {"Determine Early Regions", new DetermineEarlyRegionsMapGenStep()},
        {"Isolate Regions", new IsolateRegionsMapGenStep()},
        {"Merge Small Regions", new MergeSmallRegionsMapGenStep()},
        {"Perform Final Flood Fill", new PerformFinalFloodFillMapGenStep()},
        {"Weight And Sort Landmasses", new WeightAndSortLandmassesMapGenStep()},
        {"Determine Edges", new DetermineEdgesMapGenStep()},
        {"Determine Rivers", new DetermineRiversMapGenStep()},
        {"Carve Rivers", new CarveRiversMapGenStep()},
        {"Determine Player Start", new DeterminePlayerStartMapGenStep()},
        {"Determine Gateway Position", new DetermineGatewayPositionMapGenStep()},
        //{"Determine Regions", new DetermineRegionsMapGenStep()},
        {"Determine Region Types", new DetermineRegionTypesMapGenStep()},
        {"Populate Final Biomes", new PopulateFinalBiomesMapGenStep()},
        {"Determine Places", new DeterminePlacesMapGenStep()},
    };

    MapGen::MapGen()
        : mCurrentStage(0),
        mMapData(0) {

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
        mParentThread = new std::thread(&MapGen::beginMapGen_, this, input);
    }

    void MapGen::beginMapGen_(const ExplorationMapInputData* input){
        AV::Timer tt;
        tt.start();
        ExplorationMapGenWorkspace workspace;
        for(int i = 0; i < MAP_GEN_STEPS.size(); i++){
            AV::Timer t;
            t.start();
            MAP_GEN_STEPS[i].second->processStep(input, mMapData, &workspace);
            t.stop();
            GAME_CORE_INFO("Time taken for stage '{}' was {}", MAP_GEN_STEPS[i].first.c_str(), t.getTimeTotal());
            mCurrentStage++;
        }
        tt.stop();
        GAME_CORE_INFO("Total time for map gen was {}", tt.getTimeTotal());
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
        mParentThread->join();
        delete mParentThread;
        ExplorationMapData* out = mMapData;
        mMapData = 0;
        return out;
    }
};
