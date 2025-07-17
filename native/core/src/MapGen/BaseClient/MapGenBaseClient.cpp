#include "MapGenBaseClient.h"

#include "MapGen/MapGenStep.h"
#include "MapGen/MapGenStepMarker.h"
#include "Steps/GenerateMetaMapGenStep.h"
#include "Steps/SetupBuffersMapGenStep.h"
#include "Steps/GenerateNoiseMapGenStep.h"
#include "Steps/GenerateAdditionLayerMapGenStep.h"
#include "Steps/MergeAltitudeMapGenStep.h"
#include "Steps/ReduceNoiseMapGenStep.h"
#include "Steps/PerformFinalFloodFillMapGenStep.h"
#include "Steps/PerformPreFloodFillMapGenStep.h"
#include "Steps/RemoveRedundantIslandsMapGenStep.h"
#include "Steps/RemoveRedundantWaterMapGenStep.h"
#include "Steps/IsolateRegionsMapGenStep.h"
#include "Steps/WeightAndSortLandmassesMapGenStep.h"
#include "Steps/DetermineEarlyRegionsMapGenStep.h"
#include "Steps/DetermineEdgesMapGenStep.h"
#include "Steps/DetermineRiversMapGenStep.h"
#include "Steps/CarveRiversMapGenStep.h"
#include "Steps/DeterminePlayerStartMapGenStep.h"
#include "Steps/DetermineGatewayPositionMapGenStep.h"
#include "Steps/DetermineRegionsMapGenStep.h"
#include "Steps/DetermineRegionTypesMapGenStep.h"
#include "Steps/MergeExpandableRegionsMapGenStep.h"
#include "Steps/PopulateFinalBiomesMapGenStep.h"
#include "Steps/WriteFinalRegionValuesMapGenStep.h"
#include "Steps/PlaceItemsForBiomesMapGenStep.h"
#include "Steps/MergeSmallRegionsMapGenStep.h"
#include "Steps/MergeIsolatedRegionsMapGenStep.h"
#include "Steps/GenerateWaterTextureMapGenStep.h"
#include "Steps/CalculateRegionDistanceMapGenStep.h"
#include "Steps/RecalculateRegionEdgesMapGenStep.h"
#include "Steps/BiomeAltitudeMapGenStep.h"
#include "Steps/BiomeFinalChangesMapGenStep.h"
#include "Steps/GenerateWaterMeshMapGenStep.h"

#include "MapGen/Mesh/WaterMeshGenerator.h"
#include "OgreMeshManager2.h"
#include "OgreMesh2.h"
#include "OgreRenderSystem.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"

#include "Ogre.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "OgreTextureGpuManager.h"

namespace ProceduralExplorationGameCore{
    MapGenBaseClient::MapGenBaseClient() : MapGenClient("Base Client") {

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
            //Apply the biome altitude first so places modify the correct altitude.
            new RecalculateRegionEdgesMapGenStep(),
            new CalculateRegionDistanceMapGenStep(),

            //Perform logic to determine altitude
            new BiomeAltitudeMapGenStep(),
            new MapGenStepMarker("DeterminePlaces"),
            new RecalculateRegionEdgesMapGenStep(),
            new CalculateRegionDistanceMapGenStep(),
            new PopulateFinalBiomesMapGenStep(),
            new BiomeFinalChangesMapGenStep(),

            new PerformFinalFloodFillMapGenStep(),
            new WeightAndSortLandmassesMapGenStep(),
            new DetermineEdgesMapGenStep(),
            new DetermineRiversMapGenStep(),
            new CarveRiversMapGenStep(),
            new DeterminePlayerStartMapGenStep(),
            new DetermineGatewayPositionMapGenStep(),
            new PlaceItemsForBiomesMapGenStep(),
            new GenerateWaterTextureMapGenStep(),
            new GenerateWaterMeshMapGenStep(),
        });
    }

    void MapGenBaseClient::destroyMapData(ExplorationMapData* mapData){
        delete static_cast<AV::uint8*>(mapData->voxelBuffer);

        std::vector<RegionData>* regionData = (mapData->ptr<std::vector<RegionData>>("regionData"));
        regionData->clear();
        delete regionData;

        std::vector<PlacedItemData>* placedItemData = (mapData->ptr<std::vector<PlacedItemData>>("placedItems"));
        placedItemData->clear();
        delete placedItemData;

        std::vector<RiverData>* riverData = (mapData->ptr<std::vector<RiverData>>("riverData"));
        riverData->clear();
        delete riverData;

        std::vector<FloodFillEntry*>* waterData = (mapData->ptr<std::vector<FloodFillEntry*>>("waterData"));
        for(FloodFillEntry* e : *waterData){
            delete e;
        }
        waterData->clear();
        delete waterData;

        std::vector<FloodFillEntry*>* landData = (mapData->ptr<std::vector<FloodFillEntry*>>("landData"));
        for(FloodFillEntry* e : *landData){
            delete e;
        }
        landData->clear();
        delete landData;

        Ogre::MeshManager::getSingleton().remove("waterPlaneMesh");
    }

    void MapGenBaseClient::notifyEnded(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        for(FloodFillEntry* e : workspace->waterData){
            delete e;
        }
        for(FloodFillEntry* e : workspace->landData){
            delete e;
        }
    }

    bool MapGenBaseClient::notifyClaimed(HSQUIRRELVM vm, ExplorationMapData* mapData){
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

        //Destroy the buffers here as they're not needed anymore
        float* waterTextureBuffer = (mapData->ptr<float>("waterTextureBuffer"));
        delete waterTextureBuffer;
        float* waterTextureBufferMask = (mapData->ptr<float>("waterTextureBufferMask"));
        delete waterTextureBufferMask;

        {
            WaterMeshGenerator::MeshData* data = mapData->ptr<WaterMeshGenerator::MeshData>("waterMeshData");

            std::string totalName = "waterPlaneMesh";
            Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().createManual(totalName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Ogre::SubMesh* subMesh = mesh->createSubMesh();

            size_t vertBlocks = data->triangles.size();
            //TODO properly set the indice stride to either be 16 or 32 bit.
            static const size_t indiceStride = sizeof(AV::uint32);
            void* indices = OGRE_MALLOC_SIMD(static_cast<size_t>(vertBlocks * 3 * indiceStride), Ogre::MEMCATEGORY_GEOMETRY);
            AV::uint32* indicesPtr = static_cast<AV::uint32*>(indices);
            //size_t indiceStride = (vertBlocks * 6 * 4) + 4 >= 0xFFFF ? 4 : 2;
            for(const WaterMeshGenerator::Triangle& t : data->triangles){
                *(indicesPtr++) = t.v0;
                *(indicesPtr++) = t.v2;
                *(indicesPtr++) = t.v1;
            }

            Ogre::VertexBufferPacked *vertexBuffer = 0;
            Ogre::RenderSystem *renderSystem = Ogre::Root::getSingletonPtr()->getRenderSystem();
            Ogre::VaoManager *vaoManager = renderSystem->getVaoManager();
            static const Ogre::VertexElement2Vec elemVec = {
                Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_POSITION),
                Ogre::VertexElement2(Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES),
                Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_NORMAL)
            };

            void* vertsBuf = OGRE_MALLOC_SIMD( data->vertices.size() * sizeof(float) * 8, Ogre::MEMCATEGORY_GEOMETRY);
            float* vertsBufPtr = static_cast<float*>(vertsBuf);
            float* vertsWritePtr = vertsBufPtr;
            for(const WaterMeshGenerator::Vertex& v : data->vertices){
                *(vertsWritePtr++) = (v.pos.x - 50.0f) / 50.0;
                *(vertsWritePtr++) = v.pos.y;
                *(vertsWritePtr++) = (v.pos.z - 50.0f) / 50.0;
                *(vertsWritePtr++) = v.uv.x;
                *(vertsWritePtr++) = v.uv.y;
                *(vertsWritePtr++) = 0.0f;
                *(vertsWritePtr++) = 1.0f;
                *(vertsWritePtr++) = 0.0f;
            }

            try{
                vertexBuffer = vaoManager->createVertexBuffer(elemVec, data->vertices.size(), Ogre::BT_DEFAULT, vertsBufPtr, true);
            }catch(Ogre::Exception &e){
                vertexBuffer = 0;
            }

            Ogre::IndexBufferPacked* indexBuffer = vaoManager->createIndexBuffer(Ogre::IndexType::IT_32BIT, vertBlocks * 3, Ogre::BT_IMMUTABLE, indices, false);

            Ogre::VertexBufferPackedVec vertexBuffers;
            vertexBuffers.push_back(vertexBuffer);
            Ogre::VertexArrayObject* arrayObj = vaoManager->createVertexArrayObject(vertexBuffers, indexBuffer, Ogre::OT_TRIANGLE_LIST);

            subMesh->mVao[Ogre::VpNormal].push_back(arrayObj);
            subMesh->mVao[Ogre::VpShadow].push_back(arrayObj);

            const Ogre::Vector3 halfBounds(100 / 2, 1 / 2, 100 / 2);
            const Ogre::Aabb bounds(halfBounds, halfBounds);
            mesh->_setBounds(bounds);
            mesh->_setBoundingSphereRadius(bounds.getRadius());

            //subMesh->setMaterialName("baseVoxelMaterial");

            //return mesh;

            delete data;
        }

        return false;
    }
}
