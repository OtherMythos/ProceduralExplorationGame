#pragma once

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct ExplorationMapData;

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

    enum GameCoreHlmsProperties{
        HLMS_PACKED_VOXELS = 1u,
        HLMS_TERRAIN = 1u << 1u,
        HLMS_PACKED_OFFLINE_VOXELS = 1u << 2u,
        HLMS_OCEAN_VERTICES = 1u << 3u,
    };

    typedef AV::uint32 DataPointWrapped;
    struct DataPointData{
        float x, y, z;
        DataPointWrapped wrapped;
    };

}
