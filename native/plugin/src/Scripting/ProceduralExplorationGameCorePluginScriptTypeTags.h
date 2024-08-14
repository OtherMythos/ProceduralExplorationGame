#pragma once

#include "Scripting/ScriptObjectTypeTags.h"

namespace ProceduralExplorationGamePlugin{

    static void* ExplorationMapDataTypeTag = reinterpret_cast<void*>(AV::CUSTOM_TYPE_TAGS + 1);
    static void* VisitedPlaceMapDataTypeTag = reinterpret_cast<void*>(AV::CUSTOM_TYPE_TAGS + 2);

};
