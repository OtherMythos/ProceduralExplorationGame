#include "MapGenBaseClient.h"

#include "MapGen/MapGenStep.h"
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

#include "Ogre.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "OgreTextureGpuManager.h"

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

    void MapGenBaseClient::notifyClaimed(ExplorationMapData* mapData){
        {
            Ogre::TextureGpu* tex = 0;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->findTextureNoThrow("testTexture");
            if(!tex){
                tex = manager->createTexture("testTexture", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
                tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
                tex->setResolution(mapData->width, mapData->height);
                tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);
            }

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(mapData->width, mapData->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(mapData->width, mapData->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
            memcpy(pDest, mapData->ptr<float>("waterTextureBuffer"), mapData->width * mapData->height * sizeof(float) * 4);

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
                tex->setResolution(mapData->width, mapData->height);
                tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);
            }

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(mapData->width, mapData->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(mapData->width, mapData->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
            memcpy(pDest, mapData->ptr<float>("waterTextureBufferMask"), mapData->width * mapData->height * sizeof(float) * 4);

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
            //memcpy(pDest, mapData->waterTextureBufferMask, width * height * sizeof(float) * 4);

            stagingTexture->stopMapRegion();
            stagingTexture->upload(texBox, tex, 0, 0, 0, false);

            manager->removeStagingTexture( stagingTexture );
            stagingTexture = 0;
        }

    }
}
