#include "ProceduralExplorationGameCorePlugin.h"

#include <iostream>

#include "System/Plugins/PluginManager.h"
#include "Scripting/ScriptVM.h"
#include "Scripting/GameCoreNamespace.h"
#include "Scripting/ExplorationMapDataUserData.h"

#include "GameplayConstants.h"
#include "GameCoreLogger.h"

namespace ProceduralExplorationGamePlugin{

    extern "C" void dllStartPlugin(void){
        ProceduralExplorationGameCorePlugin* p = new ProceduralExplorationGameCorePlugin();
        AV::PluginManager::registerPlugin(p);
    }

    ProceduralExplorationGameCorePlugin::ProceduralExplorationGameCorePlugin() : Plugin("ProceduralExplorationGameCore"){

    }

    ProceduralExplorationGameCorePlugin::~ProceduralExplorationGameCorePlugin(){

    }

    void ProceduralExplorationGameCorePlugin::initialise(){
        ProceduralExplorationGameCore::GameCoreLogger::initialise();
        ProceduralExplorationGameCore::GameplayConstants::initialise();

        AV::ScriptVM::setupNamespace("_gameCore", GameCoreNamespace::setupNamespace);

        AV::ScriptVM::setupDelegateTable(ExplorationMapDataUserData::setupDelegateTable);
    }

}
