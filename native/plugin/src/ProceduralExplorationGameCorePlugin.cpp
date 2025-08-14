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

#include "Ogre.h"
#include "Ogre/OgreVoxMeshItem.h"
#include "OgreHlms.h"
#include "GameCorePBSHlmsListener.h"
#include "OgreRenderable.h"

#include "Vao/OgreConstBufferPacked.h"
#include "Vao/OgreVaoManager.h"
#include "CommandBuffer/OgreCommandBuffer.h"
#include "CommandBuffer/OgreCbShaderBuffer.h"

#include "GameCoreLogger.h"

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
    private:
        Ogre::ConstBufferPacked *mHlmsBuffer;
    public:
        HlmsGameCoreCustomHlmsListener(Ogre::ConstBufferPacked *hlmsBuffer) : mHlmsBuffer(hlmsBuffer){

        }

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
            *commandBuffer->addCommand<Ogre::CbShaderBuffer>() = Ogre::CbShaderBuffer(Ogre::VertexShader, Ogre::uint16( 3 ), mHlmsBuffer, 0, (Ogre::uint32)mHlmsBuffer->getTotalSizeBytes() );

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

        Ogre::RenderSystem *renderSystem = Ogre::Root::getSingletonPtr()->getRenderSystem();
        Ogre::VaoManager *vaoManager = renderSystem->getVaoManager();
        AV::uint8* regionAnimationBuffer = new AV::uint8[600 * 600];
        for(int i = 0; i < 600 * 600; i++){
            *(regionAnimationBuffer + i) = 0x80;
        }
        Ogre::ConstBufferPacked *hlmsBuffer = vaoManager->createConstBuffer( sizeof(AV::uint8) * 600 * 600, Ogre::BT_DEFAULT, 0, false );
        hlmsBuffer->upload( regionAnimationBuffer, 0u, sizeof(AV::uint8) * 600 * 600 );

        ProceduralExplorationGameCore::MapGen* mapGen = new ProceduralExplorationGameCore::MapGen();
        ProceduralExplorationGameCore::PluginBaseSingleton::initialise(mapGen, 0, new ProceduralExplorationGameCore::MapGenScriptManager(), {regionAnimationBuffer, hlmsBuffer});

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
        customPbs->registerCustomListener(new HlmsGameCoreCustomHlmsListener(hlmsBuffer));
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
