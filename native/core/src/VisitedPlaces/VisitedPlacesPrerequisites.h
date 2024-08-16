#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"

#include <string>
#include <vector>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData{
        AV::uint32 width;
        AV::uint32 height;

        std::string mapName;
        std::vector<AV::uint8> altitudeValues;
        std::vector<AV::uint8> voxelValues;
    };

}