#pragma once

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapData;

    typedef AV::uint8 RegionId;
    typedef AV::uint8 LandId;
    typedef AV::uint8 WaterId;
    typedef AV::uint32 WorldPoint;

    static const RegionId INVALID_REGION_ID = 0xFF;
    static const LandId INVALID_LAND_ID = 0xFF;
    static const WaterId INVALID_WATER_ID = 0xFF;
    static const WorldPoint INVALID_WORLD_POINT = 0xFFFFFFFF;

}
