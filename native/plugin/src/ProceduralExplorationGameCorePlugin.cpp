#include "ProceduralExplorationGameCorePlugin.h"

#include <iostream>

#include "System/Plugins/PluginManager.h"
#include "Scripting/ScriptVM.h"
#include "Scripting/GameCoreNamespace.h"
#include "Scripting/ExplorationMapDataUserData.h"
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
        }
        void calculateHashForPreCaster( Ogre::HlmsPbsAVCustom* hlms, Ogre::Renderable *renderable, Ogre::PiecesMap *inOutPieces, const Ogre::PiecesMap *normalPassPieces ){
            _defineProperties<true>(hlms, renderable);
        }
        void calculateHashForPreCreate( Ogre::HlmsPbsAVCustom* hlms, Ogre::Renderable *renderable, Ogre::PiecesMap *inOutPieces ){
            _defineProperties<false>(hlms, renderable);
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

        AV::ScriptVM::setupDelegateTable(ExplorationMapDataUserData::setupDelegateTable);
        AV::ScriptVM::setupDelegateTable(VisitedPlaceMapDataUserData::setupDelegateTable);
        AV::ScriptVM::setupDelegateTable(DataPointFileParserUserData::setupDelegateTable);

        ProceduralExplorationGameCore::MapGen* mapGen = new ProceduralExplorationGameCore::MapGen();
        PluginBaseSingleton::initialise(mapGen, 0, new ProceduralExplorationGameCore::MapGenScriptManager());

        Ogre::VoxMeshManager* meshManager = OGRE_NEW Ogre::VoxMeshManager();
        meshManager->_initialise();
        meshManager->_setVaoManager(Ogre::Root::getSingleton().getRenderSystem()->getVaoManager());
        Ogre::VoxMeshItemFactory* factory = OGRE_NEW Ogre::VoxMeshItemFactory();
        Ogre::Root::getSingletonPtr()->addMovableObjectFactory(factory);

        GameCorePBSHlmsListener* pbsListener = new GameCorePBSHlmsListener();
        Ogre::Hlms *hlmsPbs = Ogre::Root::getSingleton().getHlmsManager()->getHlms( Ogre::HLMS_PBS );
        hlmsPbs->setListener( pbsListener );

        Ogre::Hlms *hlmsTerra = Ogre::Root::getSingleton().getHlmsManager()->getHlms(Ogre::HLMS_USER3);
        hlmsTerra->setListener( pbsListener );

        Ogre::HlmsPbsAVCustom* customPbs = dynamic_cast<Ogre::HlmsPbsAVCustom*>(hlmsPbs);
        assert(customPbs);
        customPbs->registerCustomListener(new HlmsGameCoreCustomHlmsListener());
    }

}
