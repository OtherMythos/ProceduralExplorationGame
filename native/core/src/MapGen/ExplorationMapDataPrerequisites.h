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
        void* tertiaryVoxelBuffer;
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
    template<typename T=AV::uint32*, typename D=ExplorationMapData>
    static inline T FULL_PTR_FOR_COORD_TERTIARY(D mapData, WorldPoint p){
        WorldCoord xx;
        WorldCoord yy;
        READ_WORLD_POINT(p, xx, yy);
        return (reinterpret_cast<T>(mapData->tertiaryVoxelBuffer) + xx + yy * mapData->height);
    }

    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD<AV::uint32*, D>(mapData, p)) + N;
    }
    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD_SECONDARY(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD_SECONDARY<AV::uint32*, D>(mapData, p)) + N;
    }
    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD_TERTIARY(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD_TERTIARY<AV::uint32*, D>(mapData, p)) + N;
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

    static inline AV::uint8* VOXEL_META_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_TERTIARY<AV::uint8*, ExplorationMapData*, 0>(mapData, p);
    }
    static inline const AV::uint8* VOXEL_META_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_TERTIARY<const AV::uint8*, const ExplorationMapData*, 0>(mapData, p);
    }

    static inline AV::uint8 VOXEL_META_GET_DIFFUSE(const ExplorationMapData* mapData, WorldPoint p){
        const AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD_CONST(mapData, p);
        return *metaPtr & 0x7;
    }

    static inline void VOXEL_META_SET_DIFFUSE(ExplorationMapData* mapData, WorldPoint p, AV::uint8 diffuse){
        assert(diffuse <= 0x7);
        AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD(mapData, p);
        *metaPtr = (*metaPtr & 0xF8) | (diffuse & 0x7);
    }

    static inline AV::uint8 VOXEL_META_GET_SPEED_MODIFIER(const ExplorationMapData* mapData, WorldPoint p){
        const AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD_CONST(mapData, p);
        return (*metaPtr >> 3) & 0x7;
    }

    static inline void VOXEL_META_SET_SPEED_MODIFIER(ExplorationMapData* mapData, WorldPoint p, AV::uint8 speedModifier){
        assert(speedModifier <= 0x7);
        AV::uint8* metaPtr = VOXEL_META_PTR_FOR_COORD(mapData, p);
        *metaPtr = (*metaPtr & 0xC7) | ((speedModifier & 0x7) << 3);
    }

    static inline float VOXEL_META_GET_SPEED_MODIFIER_FLOAT(const ExplorationMapData* mapData, WorldPoint p){
        AV::uint8 value = VOXEL_META_GET_SPEED_MODIFIER(mapData, p);
        if(value <= 4){
            return 1.0f + (value * 0.25f);
        }else{
            return 1.0f - ((value - 4) * 0.25f);
        }
    }

    static inline PathId* PATH_ID_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return reinterpret_cast<PathId*>(UINT8_PTR_FOR_COORD_TERTIARY<AV::uint8*, ExplorationMapData*, 1>(mapData, p));
    }
    static inline const PathId* PATH_ID_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return reinterpret_cast<const PathId*>(UINT8_PTR_FOR_COORD_TERTIARY<const AV::uint8*, const ExplorationMapData*, 1>(mapData, p));
    }

}
