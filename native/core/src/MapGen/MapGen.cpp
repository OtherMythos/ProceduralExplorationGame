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
#include "MapGen/Steps/MergeExpandableRegionsMapGenStep.h"
#include "MapGen/Steps/PopulateFinalBiomesMapGenStep.h"
#include "MapGen/Steps/WriteFinalRegionValuesMapGenStep.h"
#include "MapGen/Steps/PlaceItemsForBiomesMapGenStep.h"
//#include "MapGen/Steps/DeterminePlacesMapGenStep.h"
#include "MapGen/Steps/MergeSmallRegionsMapGenStep.h"
#include "MapGen/Steps/MergeIsolatedRegionsMapGenStep.h"
#include "MapGen/Steps/GenerateWaterTextureMapGenStep.h"

//TODO move somewhere else
#include "Ogre.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "OgreTextureGpuManager.h"

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
        {"Write Final Region", new WriteFinalRegionValuesMapGenStep()},
        {"Merge Small Regions", new MergeSmallRegionsMapGenStep()},
        {"Merge Isolated Regions", new MergeIsolatedRegionsMapGenStep()},
        {"Determine Region Types", new DetermineRegionTypesMapGenStep()},
        {"Merge Expandable Regions", new MergeExpandableRegionsMapGenStep()},
        {"Populate Final Biomes", new PopulateFinalBiomesMapGenStep()},
        {"Perform Final Flood Fill", new PerformFinalFloodFillMapGenStep()},
        {"Weight And Sort Landmasses", new WeightAndSortLandmassesMapGenStep()},
        {"Determine Edges", new DetermineEdgesMapGenStep()},
        {"Determine Rivers", new DetermineRiversMapGenStep()},
        {"Carve Rivers", new CarveRiversMapGenStep()},
        {"Determine Player Start", new DeterminePlayerStartMapGenStep()},
        {"Determine Gateway Position", new DetermineGatewayPositionMapGenStep()},
        {"Place Items For Biomes", new PlaceItemsForBiomesMapGenStep()},
        {"Generate Water Texture", new GenerateWaterTextureMapGenStep()},
        //{"Determine Regions", new DetermineRegionsMapGenStep()},
        //{"Determine Places", new DeterminePlacesMapGenStep()},
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



        {
            Ogre::TextureGpu* tex = 0;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->findTextureNoThrow("testTexture");
            if(!tex){
                tex = manager->createTexture("testTexture", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
                tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
                tex->setResolution(out->width, out->height);
                tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);
            }

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(out->width, out->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(out->width, out->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
            memcpy(pDest, out->waterTextureBuffer, out->width * out->height * sizeof(float) * 4);

            stagingTexture->stopMapRegion();
            stagingTexture->upload(texBox, tex, 0, 0, 0, false);

            manager->removeStagingTexture( stagingTexture );
            stagingTexture = 0;
        }

        {
            Ogre::TextureGpu* tex = 0;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->findTextureNoThrow("testTextureMask");
            if(!tex){
                tex = manager->createTexture("testTextureMask", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
                tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
                tex->setResolution(out->width, out->height);
                tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);
            }

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(out->width, out->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(out->width, out->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
            memcpy(pDest, out->waterTextureBufferMask, out->width * out->height * sizeof(float) * 4);

            stagingTexture->stopMapRegion();
            stagingTexture->upload(texBox, tex, 0, 0, 0, false);

            manager->removeStagingTexture( stagingTexture );
            stagingTexture = 0;
        }

        {
            int width = 50;
            int height = 50;
            Ogre::TextureGpu* tex = 0;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->findTextureNoThrow("blueTexture");
            if(!tex){
                tex = manager->createTexture("blueTexture", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
                tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
                tex->setResolution(width, height);
                tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);
            }

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(width, height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(width, height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
            float* itPtr = pDest;
            for(int i = 0; i < width * height; i++){
                *itPtr++ = 0.0 / 255.0;
                *itPtr++ = 102.0 / 255.0;
                *itPtr++ = 255.0 / 255.0;
                *itPtr++ = 255.0 / 255.0;
            }
            //memcpy(pDest, out->waterTextureBufferMask, width * height * sizeof(float) * 4);

            stagingTexture->stopMapRegion();
            stagingTexture->upload(texBox, tex, 0, 0, 0, false);

            manager->removeStagingTexture( stagingTexture );
            stagingTexture = 0;
        }


        return out;
    }
};
