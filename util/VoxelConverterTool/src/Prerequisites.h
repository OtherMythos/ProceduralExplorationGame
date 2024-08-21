#pragma once

#include <cstddef>

namespace VoxelConverterTool{

    typedef unsigned char uint8;
    typedef unsigned short uint16;
    typedef unsigned int uint32;
    typedef unsigned long long uint64;

    typedef uint16 VoxelId;
    static const VoxelId EMPTY_VOXEL = 0x8000;
    typedef uint64 WrappedFace;

    struct WrappedFaceContainer{
        uint8 x, y, z;
        VoxelId vox;
        uint8 ambientMask;
        uint8 faceMask;
    };
    static WrappedFace _wrapFace(const WrappedFaceContainer& c){
        return c.x | c.y << 8 | c.z << 16 | c.vox << 24 | static_cast<uint64>(c.ambientMask) << 32 | static_cast<uint64>(c.faceMask) << 34;
    }

    static void _unwrapFace(WrappedFace f, WrappedFaceContainer& o){
        o.x = f & 0xFF;
        o.y = (f >> 8) & 0xFF;
        o.z = (f >> 16) & 0xFF;
        o.vox = (f >> 24) & 0xFF;
        o.ambientMask = (f >> 32) & 0x3;
        o.faceMask = (f >> 34) & 0xFF;
    }

}
