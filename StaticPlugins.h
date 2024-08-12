//Setup static plugins

#pragma once

#include "native/plugin/src/ProceduralExplorationGameCorePlugin.h"

void registerStaticPlugins(){
    REGISTER_PLUGIN("ProceduralExplorationGamePlugin", ProceduralExplorationGamePlugin::ProceduralExplorationGameCorePlugin)
}
