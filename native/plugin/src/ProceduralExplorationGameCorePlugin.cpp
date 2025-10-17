#include "ProceduralExplorationGameCorePlugin.h"

#include <iostream>

#include "System/Plugins/PluginManager.h"
#include "Scripting/ScriptVM.h"
#include "Scripting/GameCoreNamespace.h"
#include "MapGen/Script/ExplorationMapDataUserData.h"
#include "Scripting/VisitedPlaceMapDataUserData.h"
#include "Scripting/DataPointFileUserData.h"

#include "Voxeliser/VoxSceneDumper.h"
#include "Ogre.h"
#include "OgreHlmsPbs.h"
#include "OgreHlmsPbsDatablock.h"
#include "System/OgreSetup/CustomHLMS/OgreHlmsPbsAVCustom.h"
#include "MapGen/MapGen.h"
#include "MapGen/Script/MapGenScriptManager.h"
#include "PluginBaseSingleton.h"

#include "GameplayConstants.h"
#include "GameCoreLogger.h"

#include "Ogre/OgreVoxMeshItem.h"
#include "Ogre/OgreVoxMeshManager.h"

#include "Gui/GuiManager.h"

#include "System/Base.h"
#include "System/BaseSingleton.h"

#include "MapGen/Mesh/WaterMeshGenerator.h"
#include "OgreMeshManager2.h"
#include "OgreMesh2.h"
#include "OgreRenderSystem.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"

#include "Ogre.h"
#include "Ogre/OgreVoxMeshItem.h"
#include "OgreHlms.h"
#include "OgreTextureGpuManager.h"
#include "OgreStagingTexture.h"
#include "OgreTextureBox.h"
#include "GameCorePBSHlmsListener.h"
#include "OgreRenderable.h"

namespace ProceduralExplorationGamePlugin{

#ifdef WIN32
    #define DLLEXPORT __declspec(dllexport)
#else
    #define DLLEXPORT
#endif

    extern "C" DLLEXPORT void dllStartPlugin(void){
        ProceduralExplorationGameCorePlugin* p = new ProceduralExplorationGameCorePlugin();
        AV::PluginManager::registerPlugin(p);
    }

    class HlmsGameCoreCustomHlmsListener : public Ogre::HlmsAVCustomListener{
    public:
        template <bool CasterPass>
        inline void _defineProperties(Ogre::HlmsPbsAVCustom* hlms, Ogre::Renderable *renderable){
            if(!renderable->hasCustomParameter(0)) return;
            const Ogre::Vector4& params = renderable->getCustomParameter(0);
            AV::uint32 v = *(reinterpret_cast<const AV::uint32*>(&params.x));

            if(v & ProceduralExplorationGameCore::HLMS_PACKED_VOXELS){
                hlms->setProperty("packedVoxels", true);
                if(!CasterPass){
                    hlms->setProperty( Ogre::HlmsBaseProp::Normal, 1 );
                    hlms->setProperty( Ogre::HlmsBaseProp::UvCount0, Ogre::v1::VertexElement::getTypeCount( Ogre::VET_FLOAT2 ) );
                    const Ogre::uint32 numTextures = 1u;
                    hlms->setProperty( Ogre::HlmsBaseProp::UvCount, numTextures );
                }
            }
            if(v & ProceduralExplorationGameCore::HLMS_TERRAIN){
                hlms->setProperty("voxelTerrain", true);
            }
            if(v & ProceduralExplorationGameCore::HLMS_PACKED_OFFLINE_VOXELS){
                hlms->setProperty("offlineVoxels", true);
            }
            if(v & ProceduralExplorationGameCore::HLMS_OCEAN_VERTICES){
                hlms->setProperty("oceanVertices", true);
            }
            if(v & ProceduralExplorationGameCore::HLMS_TREE_VERTICES){
                hlms->setProperty("treeVertices", true);
            }
            if(v & ProceduralExplorationGameCore::HLMS_WIND_STREAKS){
                hlms->setProperty("windStreaks", true);
            }
            if(v & ProceduralExplorationGameCore::HLMS_FLOOR_DECALS){
                hlms->setProperty("floorDecals", true);
            }
        }
        void calculateHashForPreCaster( Ogre::HlmsPbsAVCustom* hlms, Ogre::Renderable *renderable, Ogre::PiecesMap *inOutPieces, const Ogre::PiecesMap *normalPassPieces ){
            _defineProperties<true>(hlms, renderable);
        }
        void calculateHashForPreCreate( Ogre::HlmsPbsAVCustom* hlms, Ogre::Renderable *renderable, Ogre::PiecesMap *inOutPieces ){
            _defineProperties<false>(hlms, renderable);
        }
        Ogre::uint32 fillBuffersForV2(const Ogre::HlmsCache *cache, const Ogre::QueuedRenderable &queuedRenderable, bool casterPass, Ogre::uint32 lastCacheHash, Ogre::CommandBuffer *commandBuffer){
            return 0;
        }
    };


    ProceduralExplorationGameCorePlugin::ProceduralExplorationGameCorePlugin() : Plugin("ProceduralExplorationGameCore"){

    }

    ProceduralExplorationGameCorePlugin::~ProceduralExplorationGameCorePlugin(){

    }

    void writeFlagToDatablock(const char* blockName, AV::uint32 flag, const char* cloneName = 0){
        Ogre::Hlms *hlmsPbs = Ogre::Root::getSingleton().getHlmsManager()->getHlms( Ogre::HLMS_PBS );
        Ogre::HlmsDatablock* db = hlmsPbs->getDatablock(blockName);
        if(db == 0) return;
        Ogre::HlmsPbsDatablock* pbsDb = dynamic_cast<Ogre::HlmsPbsDatablock*>(db);
        if(cloneName != 0){
            Ogre::HlmsDatablock* newDb = pbsDb->clone(cloneName);
            pbsDb = dynamic_cast<Ogre::HlmsPbsDatablock*>(newDb);
        }

        Ogre::Vector4 vals = Ogre::Vector4::ZERO;
        vals.x = *reinterpret_cast<Ogre::Real*>(&flag);
        pbsDb->setUserValue(0, vals);
    }

    void ProceduralExplorationGameCorePlugin::initialise(){
        ProceduralExplorationGameCore::GameCoreLogger::initialise();
        GAME_CORE_INFO("Beginning initialisation for game core plugin");

        ProceduralExplorationGameCore::GameplayConstants::initialise();

        AV::ScriptVM::setupNamespace("_gameCore", GameCoreNamespace::setupNamespace);

        AV::ScriptVM::setupDelegateTable(ProceduralExplorationGameCore::ExplorationMapDataUserData::setupDelegateTable<false>);
        AV::ScriptVM::setupDelegateTable(VisitedPlaceMapDataUserData::setupDelegateTable);
        AV::ScriptVM::setupDelegateTable(DataPointFileParserUserData::setupDelegateTable);

        ProceduralExplorationGameCore::MapGen* mapGen = new ProceduralExplorationGameCore::MapGen();
        ProceduralExplorationGameCore::PluginBaseSingleton::initialise(mapGen, 0, new ProceduralExplorationGameCore::MapGenScriptManager());

        Ogre::VoxMeshManager* meshManager = OGRE_NEW Ogre::VoxMeshManager();
        meshManager->_initialise();
        meshManager->_setVaoManager(Ogre::Root::getSingleton().getRenderSystem()->getVaoManager());
        Ogre::VoxMeshItemFactory* factory = OGRE_NEW Ogre::VoxMeshItemFactory();
        Ogre::Root::getSingletonPtr()->addMovableObjectFactory(factory);
        mMovableFactory = factory;

        GameCorePBSHlmsListener* pbsListener = new GameCorePBSHlmsListener();
        Ogre::Hlms *hlmsPbs = Ogre::Root::getSingleton().getHlmsManager()->getHlms( Ogre::HLMS_PBS );
        hlmsPbs->setListener( pbsListener );

        Ogre::Hlms *hlmsTerra = Ogre::Root::getSingleton().getHlmsManager()->getHlms(Ogre::HLMS_USER3);
        hlmsTerra->setListener( pbsListener );

        Ogre::HlmsPbsAVCustom* customPbs = dynamic_cast<Ogre::HlmsPbsAVCustom*>(hlmsPbs);
        assert(customPbs);
        customPbs->registerCustomListener(new HlmsGameCoreCustomHlmsListener());

        {
            ProceduralExplorationGameCore::WaterMeshGenerator gen;
            std::vector<ProceduralExplorationGameCore::WaterMeshGenerator::Hole> holes;
            ProceduralExplorationGameCore::ExplorationMapData mapData;
            mapData.width = 600;
            mapData.height = 600;
            mapData.seaLevel = 100;
            mapData.blueNoiseBuffer = 0;
            mapData.voxelBuffer = 0;
            mapData.secondaryVoxelBuffer = 0;
            ProceduralExplorationGameCore::WaterMeshGenerator::MeshData meshData = gen.generateMesh(100, 100, holes, &mapData);

            ProceduralExplorationGameCore::WaterMeshGenerator::MeshData* data = new ProceduralExplorationGameCore::WaterMeshGenerator::MeshData();
            data->triangles = std::move(meshData.triangles);
            data->vertices = std::move(meshData.vertices);
            //mapData->voidPtr("waterMeshData", reinterpret_cast<void*>(data));

            //WaterMeshGenerator::MeshData* data = mapData->ptr<WaterMeshGenerator::MeshData>("waterMeshData");

            std::string totalName = "simpleWaterPlaneMesh";
            Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().createManual(totalName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
            Ogre::SubMesh* subMesh = mesh->createSubMesh();

            size_t vertBlocks = data->triangles.size();
            //TODO properly set the indice stride to either be 16 or 32 bit.
            static const size_t indiceStride = sizeof(AV::uint32);
            void* indices = OGRE_MALLOC_SIMD(static_cast<size_t>(vertBlocks * 3 * indiceStride), Ogre::MEMCATEGORY_GEOMETRY);
            AV::uint32* indicesPtr = static_cast<AV::uint32*>(indices);
            //size_t indiceStride = (vertBlocks * 6 * 4) + 4 >= 0xFFFF ? 4 : 2;
            for(const ProceduralExplorationGameCore::WaterMeshGenerator::Triangle& t : data->triangles){
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
            for(const ProceduralExplorationGameCore::WaterMeshGenerator::Vertex& v : data->vertices){
                *(vertsWritePtr++) = ((100.0 / 99.0) * v.pos.x - 50.0f) / 50.0;
                *(vertsWritePtr++) = v.pos.y;
                *(vertsWritePtr++) = ((100.0 / 99.0) * v.pos.z - 50.0f) / 50.0;
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

        {
            int width = 50;
            int height = 50;
            Ogre::TextureGpu* tex = 0;
            Ogre::TextureGpuManager* manager = Ogre::Root::getSingletonPtr()->getRenderSystem()->getTextureGpuManager();
            tex = manager->findTextureNoThrow("blueTexture");
            if(tex){
                manager->destroyTexture(tex);
            }
            tex = manager->createTexture("blueTexture", Ogre::GpuPageOutStrategy::Discard, Ogre::TextureFlags::ManualTexture, Ogre::TextureTypes::Type2DArray);
            tex->setPixelFormat(Ogre::PixelFormatGpu::PFG_RGBA32_FLOAT);
            tex->setResolution(width, height);
            tex->scheduleTransitionTo(Ogre::GpuResidency::Resident);

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

    void ProceduralExplorationGameCorePlugin::shutdown(){
        GAME_CORE_INFO("Shutting down game core plugin");

        Ogre::Root::getSingletonPtr()->removeMovableObjectFactory(mMovableFactory);
        OGRE_DELETE mMovableFactory;
        mMovableFactory = 0;

        ProceduralExplorationGameCore::MapGen* mapGen = ProceduralExplorationGameCore::PluginBaseSingleton::getMapGen();
        delete mapGen;
    }

}
