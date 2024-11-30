#pragma once
#define enum enum class
#define const static const AV::uint32

/*
::VoxelValues <- [
   2, 112, 0, 147, 6, 198, 199
];
*/

#if 0
::VoxelValues <- [
#endif
#define VOXEL_VALUES \
   2, 112, 0, 147, 6, 198, 199
#if 0
];
#endif


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
const MAP_VOXEL_MASK = 0x1F;

enum BiomeId{
    NONE,

    GRASS_LAND,
    GRASS_FOREST,
    CHERRY_BLOSSOM_FOREST,
    EXP_FIELD,
    DESERT,

    SHALLOW_OCEAN,
    DEEP_OCEAN,

    MAX
};

enum RegionType{
    NONE,

    GRASSLAND,
    CHERRY_BLOSSOM_FOREST,
    EXP_FIELDS,
    DESERT,
    GATEWAY_DOMAIN,
    PLAYER_START
};

enum RegionMeta{
    MAIN_REGION = 0x1,
    EXPANDABLE = 0x2
};

/**
 * Generally aestetic things like trees, rocks, etc.
 */
enum PlacedItemId{
    NONE,

    TREE,
    CHERRY_BLOSSOM_TREE,
    CACTUS,
    TREE_APPLE,

    MAX
};

#undef enum
#undef const
