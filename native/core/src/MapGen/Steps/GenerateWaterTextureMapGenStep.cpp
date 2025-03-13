#include "GenerateWaterTextureMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/Biomes.h"

#include <cassert>
#include <cstring>

namespace ProceduralExplorationGameCore{

    GenerateWaterTextureMapGenStep::GenerateWaterTextureMapGenStep(){

    }

    GenerateWaterTextureMapGenStep::~GenerateWaterTextureMapGenStep(){

    }

    void GenerateWaterTextureMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        /*
            Ogre::TextureGpu* tex;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->createTexture("testTexture", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2D);
            tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA8_UNORM);
            tex->setResolution(input->width, input->height);
            tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);

            Ogre::StagingTexture *stagingTexture = manager->getStagingTexture(input->width, input->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());
            stagingTexture->startMapRegion();
            Ogre::TextureBox texBox = stagingTexture->mapRegion(input->width, input->height, tex->getDepth(), tex->getNumSlices(), tex->getPixelFormat());

            Ogre::uint8* pDest = static_cast<Ogre::uint8*>(texBox.at(0, 0, 0));
         */

        size_t bufSize = input->width * input->height * sizeof(float) * 4;
        AV::uint32* buffer = static_cast<AV::uint32*>(malloc(bufSize));
        memset(buffer, 0, bufSize);

        /*
        for(int y = 0; y < input->height; y++){
            for(int x = 0; x < input->width; x++){
                const WorldPoint altitudePoint = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, altitudePoint);

                if(*altitude >= mapData->seaLevel){
                    continue;
                }

                *(buffer + (x + y * input->width)) = 100;

            }
        }
         */


        int div = 4;
        int divWidth = input->width / div;
        int divHeight = input->height / div;
        for(int y = 0; y < div; y++){
            for(int x = 0; x < div; x++){
                GenerateWaterTextureMapGenJob job;
                job.processJob(mapData, buffer, x * divWidth, y * divHeight, x * divWidth + divWidth, y * divHeight + divHeight);
            }
        }

        /*
        stagingTexture->stopMapRegion();
        stagingTexture->upload(texBox, tex, 0, 0, 0, false);

        manager->removeStagingTexture( stagingTexture );
        stagingTexture = 0;
         */

        mapData->waterTextureBuffer = buffer;
    }

    GenerateWaterTextureMapGenJob::GenerateWaterTextureMapGenJob(){

    }

    GenerateWaterTextureMapGenJob::~GenerateWaterTextureMapGenJob(){

    }

    void GenerateWaterTextureMapGenJob::processJob(ExplorationMapData* mapData, AV::uint32* buffer, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                const WorldPoint altitudePoint = WRAP_WORLD_POINT(x, y);
                const AV::uint8* altitude = VOX_PTR_FOR_COORD_CONST(mapData, altitudePoint);
                const AV::uint8* waterGroup = WATER_GROUP_PTR_FOR_COORD_CONST(mapData, altitudePoint);

                /*
                if(*altitude >= mapData->seaLevel){
                    continue;
                }
                 */

                float* b = reinterpret_cast<float*>((buffer) + (x + (mapData->height - y) * mapData->width) * 4);

                if(*waterGroup == 0 || *waterGroup == INVALID_WATER_ID){
                    if(*altitude >= mapData->seaLevel - 20){
                        *(b++) = 0.4;
                        *(b++) = 0.4;
                        *(b++) = 1;
                    }else{
                        *(b++) = 0;
                        *(b++) = 0;
                        *(b++) = 1;
                    }
                }else{
                    *(b++) = 0.2;
                    *(b++) = 0.2;
                    *(b++) = 0.8;
                }
                *(b++) = 0xFF;

            }
        }
    }

}
