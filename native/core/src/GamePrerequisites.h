#pragma once

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapData;

    typedef AV::uint16 VoxelId;
    static const VoxelId EMPTY_VOXEL = 0x8000;

    typedef AV::uint8 RegionId;
    typedef AV::uint8 LandId;
    typedef AV::uint8 WaterId;
    typedef AV::uint16 WorldCoord;
    typedef AV::uint32 WorldPoint;

    static const RegionId INVALID_REGION_ID = 0xFF;
    static const LandId INVALID_LAND_ID = 0xFF;
    static const WaterId INVALID_WATER_ID = 0xFF;
    static const WorldPoint INVALID_WORLD_POINT = 0xFFFFFFFF;
    static const RegionId REGION_ID_WATER = 253;

    typedef AV::uint32 DataPointWrapped;
    struct DataPointData{
        float x, y, z;
        DataPointWrapped wrapped;
    };

}
