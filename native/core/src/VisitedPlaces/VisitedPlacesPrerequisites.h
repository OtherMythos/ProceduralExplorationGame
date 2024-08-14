#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"

#include <string>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData{
        AV::uint32 width;
        AV::uint32 height;

        std::string mapName;
    };

}