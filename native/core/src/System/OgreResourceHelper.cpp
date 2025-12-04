#include "OgreResourceHelper.h"

#include "Ogre.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "OgreTextureGpuManager.h"

#include <cstring>

namespace ProceduralExplorationGameCore{

    OgreResourceHelper::OgreResourceHelper(){

    }

    OgreResourceHelper::~OgreResourceHelper(){

    }

    void OgreResourceHelper::destroyTextureIfExists(const std::string& textureName){
        Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
        Ogre::TextureGpu* tex = manager->findTextureNoThrow(textureName);
        if(tex){
            manager->destroyTexture(tex);
        }
    }

    void OgreResourceHelper::createTextureFromBuffer(const std::string& textureName, AV::uint32 width, AV::uint32 height, float* buffer){
        destroyTextureIfExists(textureName);

        Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
        Ogre::TextureGpu* tex = manager->createTexture(textureName, Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
        tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
        tex->setResolution(width, height);
        tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);

        Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(width, height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
        stagingTexture->startMapRegion();
        Ogre::TextureBox texBox = stagingTexture->mapRegion(width, height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

        float* pDest = static_cast<float*>(texBox.at(0, 0, 0));
        memcpy(pDest, buffer, width * height * sizeof(float) * 4);

        stagingTexture->stopMapRegion();
        stagingTexture->upload(texBox, tex, 0, 0, 0, false);

        manager->removeStagingTexture(stagingTexture);
    }

}
