#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"
#include "MapGenDataContainer.h"

#include "RandomWrapper.h"

#include <vector>
#include <string>
#include <set>
#include <cassert>

namespace ProceduralExplorationGameCore{

    class ExplorationMapData : public MapGenDataContainer{
    public:
        AV::uint32 width;
        AV::uint32 height;
        AV::uint32 seaLevel;

        void* voxelBuffer;
        void* secondaryVoxelBuffer;
        void* blueNoiseBuffer;
    };

    static inline WorldPoint WRAP_WORLD_POINT(WorldCoord x, WorldCoord y){
        return (static_cast<WorldPoint>(x) << 16) | y;
    }

    static inline void READ_WORLD_POINT(WorldPoint point, WorldCoord& xx, WorldCoord& yy){
        xx = (point >> 16) & 0xFFFF;
        yy = point & 0xFFFF;
    }

    template<typename T=AV::uint32*, typename D=ExplorationMapData*>
    static inline T FULL_PTR_FOR_COORD(D mapData, WorldPoint p){
        WorldCoord xx;
        WorldCoord yy;
        READ_WORLD_POINT(p, xx, yy);
        return (reinterpret_cast<T>(mapData->voxelBuffer) + xx + yy * mapData->height);
    }
    template<typename T=AV::uint32*, typename D=ExplorationMapData>
    static inline T FULL_PTR_FOR_COORD_SECONDARY(D mapData, WorldPoint p){
        WorldCoord xx;
        WorldCoord yy;
        READ_WORLD_POINT(p, xx, yy);
        return (reinterpret_cast<T>(mapData->secondaryVoxelBuffer) + xx + yy * mapData->height);
    }

    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD<AV::uint32*, D>(mapData, p)) + N;
    }
    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD_SECONDARY(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD_SECONDARY<AV::uint32*, D>(mapData, p)) + N;
    }

    static inline AV::uint8* VOX_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 0>(mapData, p);
    }
    static inline AV::uint8* VOX_VALUE_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 1>(mapData, p);
    }
    static inline AV::uint8* WATER_GROUP_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 2>(mapData, p);
    }
    static inline AV::uint8* LAND_GROUP_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 3>(mapData, p);
    }
    //Const
    static inline const AV::uint8* VOX_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 0>(mapData, p);
    }
    static inline const AV::uint8* VOX_VALUE_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 1>(mapData, p);
    }
    static inline const AV::uint8* WATER_GROUP_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 2>(mapData, p);
    }
    static inline const AV::uint8* LAND_GROUP_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 3>(mapData, p);
    }

    static inline AV::uint8* REGION_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<AV::uint8*, ExplorationMapData*, 1>(mapData, p);
    }
    static inline const AV::uint8* REGION_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<const AV::uint8*, const ExplorationMapData*, 1>(mapData, p);
    }
    static inline AV::uint8* REGION_DISTANCE_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<AV::uint8*, ExplorationMapData*, 2>(mapData, p);
    }
    static inline const AV::uint8* REGION_DISTANCE_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<const AV::uint8*, const ExplorationMapData*, 2>(mapData, p);
    }
    static inline AV::uint8* VOXEL_FLAGS_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<AV::uint8*, ExplorationMapData*, 3>(mapData, p);
    }
    static inline const AV::uint8* VOXEL_FLAGS_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<const AV::uint8*, const ExplorationMapData*, 3>(mapData, p);
    }

}
