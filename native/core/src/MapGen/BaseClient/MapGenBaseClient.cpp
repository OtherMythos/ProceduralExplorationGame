#include "MapGenBaseClient.h"

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
#include "MapGen/Steps/MergeExpandableRegionsMapGenStep.h"
#include "MapGen/Steps/PopulateFinalBiomesMapGenStep.h"
#include "MapGen/Steps/WriteFinalRegionValuesMapGenStep.h"
#include "MapGen/Steps/PlaceItemsForBiomesMapGenStep.h"
//#include "MapGen/Steps/DeterminePlacesMapGenStep.h"
#include "MapGen/Steps/MergeSmallRegionsMapGenStep.h"
#include "MapGen/Steps/MergeIsolatedRegionsMapGenStep.h"
#include "MapGen/Steps/GenerateWaterTextureMapGenStep.h"

namespace ProceduralExplorationGameCore{
    MapGenBaseClient::MapGenBaseClient(){

    }

    MapGenBaseClient::~MapGenBaseClient(){

    }

    void MapGenBaseClient::populateSteps(std::vector<MapGenStep*>& steps){
        steps.insert(steps.end(), {
            new GenerateMetaMapGenStep(),
            new SetupBuffersMapGenStep(),
            new GenerateNoiseMapGenStep(),
            new GenerateAdditionLayerMapGenStep(),
            new MergeAltitudeMapGenStep(),
            new ReduceNoiseMapGenStep(),
            new PerformPreFloodFillMapGenStep(),
            new RemoveRedundantIslandsMapGenStep(),
            new RemoveRedundantWaterMapGenStep(),
            new DetermineEarlyRegionsMapGenStep(),
            new IsolateRegionsMapGenStep(),
            new WriteFinalRegionValuesMapGenStep(),
            new MergeSmallRegionsMapGenStep(),
            new MergeIsolatedRegionsMapGenStep(),
            new DetermineRegionTypesMapGenStep(),
            new MergeExpandableRegionsMapGenStep(),
            new PopulateFinalBiomesMapGenStep(),
            new PerformFinalFloodFillMapGenStep(),
            new WeightAndSortLandmassesMapGenStep(),
            new DetermineEdgesMapGenStep(),
            new DetermineRiversMapGenStep(),
            new CarveRiversMapGenStep(),
            new DeterminePlayerStartMapGenStep(),
            new DetermineGatewayPositionMapGenStep(),
            new PlaceItemsForBiomesMapGenStep(),
            new GenerateWaterTextureMapGenStep(),
        });
    }
}
