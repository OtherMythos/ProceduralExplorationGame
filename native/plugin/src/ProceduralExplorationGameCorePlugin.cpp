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

#include "GameplayConstants.h"
#include "GameCoreLogger.h"

#include "Ogre/OgreVoxMeshItem.h"
#include "Ogre/OgreVoxMeshManager.h"

#include "Gui/GuiManager.h"

#include "System/Base.h"
#include "System/BaseSingleton.h"

#include "Ogre.h"
#include "Ogre/OgreVoxMeshItem.h"

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

    ProceduralExplorationGameCorePlugin::ProceduralExplorationGameCorePlugin() : Plugin("ProceduralExplorationGameCore"){

    }

    ProceduralExplorationGameCorePlugin::~ProceduralExplorationGameCorePlugin(){

    }

    void ProceduralExplorationGameCorePlugin::initialise(){
        ProceduralExplorationGameCore::GameCoreLogger::initialise();
        GAME_CORE_INFO("Beginning initialisation for game core plugin");

        ProceduralExplorationGameCore::GameplayConstants::initialise();

        AV::ScriptVM::setupNamespace("_gameCore", GameCoreNamespace::setupNamespace);

        AV::ScriptVM::setupDelegateTable(ExplorationMapDataUserData::setupDelegateTable);
        AV::ScriptVM::setupDelegateTable(VisitedPlaceMapDataUserData::setupDelegateTable);
        AV::ScriptVM::setupDelegateTable(DataPointFileParserUserData::setupDelegateTable);

        Ogre::VoxMeshManager* meshManager = OGRE_NEW Ogre::VoxMeshManager();
        meshManager->_initialise();
        meshManager->_setVaoManager(Ogre::Root::getSingleton().getRenderSystem()->getVaoManager());
        Ogre::VoxMeshItemFactory* factory = OGRE_NEW Ogre::VoxMeshItemFactory();
        Ogre::Root::getSingletonPtr()->addMovableObjectFactory(factory);

        ProceduralExplorationGameCore::VoxSceneDumper dumper;
        auto it = Ogre::Root::getSingleton().getSceneManagerIterator();
        //dumper.dumpToObjFile("/tmp/out.obj", it.getNext()->getRootSceneNode());

    }

}
