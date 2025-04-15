#include "MapGen.h"

#include <thread>
#include <cassert>

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/MapGenClient.h"
//TODO move the base out of the steps class.
#include "MapGen/Steps/MapGenStep.h"
#include "MapGen/BaseClient/MapGenBaseClient.h"
#include "GameCoreLogger.h"


//TODO move somewhere else
#include "Ogre.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "OgreTextureGpuManager.h"

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
    }

    void MapGen::beginMapGen(const ExplorationMapInputData* input){
        assert(!mMapData);

        mMapData = new ExplorationMapData();
        mMapInputData = input;
        mParentThread = new std::thread(&MapGen::beginMapGen_, this, input, mMapGenSteps);
    }

    void MapGen::beginMapGen_(const ExplorationMapInputData* input, const std::vector<MapGenStep*>& steps){
        AV::Timer tt;
        tt.start();
        ExplorationMapGenWorkspace workspace;
        for(int i = 0; i < steps.size(); i++){
            AV::Timer t;
            t.start();
            steps[i]->processStep(input, mMapData, &workspace);
            t.stop();
            GAME_CORE_INFO("Time taken for stage '{}' was {}", steps[i]->getName(), t.getTimeTotal());
            mCurrentStage++;
        }
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
