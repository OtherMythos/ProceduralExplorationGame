#pragma once

namespace VoxelConverterTool{

    typedef unsigned char uint8;
    typedef unsigned short uint16;
    typedef unsigned int uint32;
    typedef unsigned long long uint64;

    typedef uint16 VoxelId;
    static const VoxelId EMPTY_VOXEL = 0x8000;
    typedef uint64 WrappedFace;

    static WrappedFace _wrapFace(uint8 x, uint8 y, uint8 z, VoxelId vox, uint8 ambientMask, uint8 faceMask){
        return x | y << 8 | z << 16 | vox << 24 | ambientMask << 32 | faceMask << 34;
    }

}
