#pragma once

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    typedef AV::uint32 WorldPoint;

    enum MapVoxelTypes{
        SAND,
        DIRT,
        SNOW,
        TREES,
        TREES_CHERRY_BLOSSOM,

        DIRT_EXP_FIELD,
        SAND_EXP_FIELD,

        EDGE = 0x40,
        RIVER = 0x20,
    };
    //The mask is used to include the edge and river flags.
    static const AV::uint32 MAP_VOXEL_MASK = 0x1F;

    struct ExplorationMapData{
        AV::uint32 width;
        AV::uint32 height;

        AV::uint32 seed;
        AV::uint32 moistureSeed;
        AV::uint32 variationSeed;

        AV::uint32 seaLevel;

        WorldPoint playerStart;
        WorldPoint gatewayPosition;

        void* voxelBuffer;
        void* secondaryVoxelBuffer;
        void* blueNoiseBuffer;
        void* riverBuffer;

        struct BufferData{
            size_t size;
            size_t voxel;
            size_t secondaryVoxel;
            size_t blueNoise;
            size_t river;
        };
        void calculateBuffer(BufferData* buf){
            size_t voxTotal = width * height;
            buf->voxel = 0;
            buf->size += voxTotal * sizeof(AV::uint32);
            buf->secondaryVoxel = buf->size;
            buf->size += voxTotal * sizeof(AV::uint32);
            buf->blueNoise = buf->size;
        }

        //~ExplorationMapData(){
            //free(voxelBuffer);
        //}
    };

}
