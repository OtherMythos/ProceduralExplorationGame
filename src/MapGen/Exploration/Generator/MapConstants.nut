
enum MapVoxelTypes{
    SAND,
    DIRT,
    SNOW,
    TREES,
    TREES_CHERRY_BLOSSOM,

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

    SHALLOW_OCEAN,
    DEEP_OCEAN,

    MAX
};

/**
 * Generally aestetic things like trees, rocks, etc.
 */
enum PlacedItemId{
    NONE,

    TREE,
    CHERRY_BLOSSOM_TREE,

    MAX
};