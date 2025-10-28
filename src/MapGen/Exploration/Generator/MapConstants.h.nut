#pragma once
#define enum enum class
#define const static const AV::uint32

const MAX_VOXELS = 0xFF;

//10-19 - Rendered and included in the shadow map.
const RENDER_QUEUE_EXPLORATION_WATER = 18; //Render water last to prevent overdraw.
const RENDER_QUEUE_EXPLORATION_TERRRAIN_DISCOVERED = 12;
const RENDER_QUEUE_EXPLORATION = 15;
const RENDER_QUEUE_EXPLORATION_EFFECTS = 16;
const RENDER_QUEUE_EXPLORATION_NO_LINES = 17;
//20 - 29 - Rendered and not included in the shadow map
//30 - 39 - Not rendered but included in the shadow map
const RENDER_QUEUE_EXPLORATION_CLOUD = 30;
//40 - 50 - Miscellaneous for the gameplay scene
const RENDER_QUEUE_EXPLORATION_WIND = 40;
const RENDER_QUEUE_EXPLORATION_TERRRAIN_UNDISCOVERED = 41;

const RENDER_QUEUE_INVENTORY_PREVIEW = 50;
const RENDER_QUEUE_EFFECT_BG = 60;
const RENDER_QUEUE_EFFECT_FG = 65;

enum MapVoxelTypes{
    SAND,
    DIRT,
    SNOW,
    TREES,
    TREES_CHERRY_BLOSSOM,

    DIRT_EXP_FIELD,
    SAND_EXP_FIELD,

    SWAMP_GRASS,
    SWAMP_FOREST_GRASS,
};

enum BiomeId{
    NONE,

    GRASS_LAND,
    GRASS_FOREST,
    CHERRY_BLOSSOM_FOREST,
    EXP_FIELD,
    DESERT,
    SWAMP,

    SHALLOW_OCEAN,
    DEEP_OCEAN,

    MAX
};

const HLMS_PACKED_VOXELS = 0x1;
const HLMS_TERRAIN = 0x2;
const HLMS_PACKED_OFFLINE_VOXELS = 0x4;
const HLMS_OCEAN_VERTICES = 0x8;
const HLMS_TREE_VERTICES = 0x10;
const HLMS_WIND_STREAKS = 0x20;
const HLMS_FLOOR_DECALS = 0x40;

enum RegionType{
    NONE,

    GRASSLAND,
    CHERRY_BLOSSOM_FOREST,
    EXP_FIELDS,
    DESERT,
    SWAMP,
    GATEWAY_DOMAIN,
    PLAYER_START
};

enum RegionMeta{
    MAIN_REGION = 0x1,
    EXPANDABLE = 0x2
};

const DO_NOT_PLACE_ITEMS_VOXEL_FLAG = 0x1000000;
const SKIP_DRAW_TERRAIN_VOXEL_FLAG = 0x2000000;
const RIVER_VOXEL_FLAG = 0x4000000;
const DRAW_COLOUR_VOXEL_FLAG = 0x8000000;
const DO_NOT_PLACE_RIVERS_VOXEL_FLAG = 0x10000000;
const TEST_CHANGE_WATER_FLAG = 0x20000000;
const DO_NOT_CHANGE_VOXEL = 0x40000000;

/**
 * Generally aestetic things like trees, rocks, etc.
 */
enum PlacedItemId{
    NONE,

    TREE,
    CHERRY_BLOSSOM_TREE,
    CACTUS,
    TREE_APPLE,
    PALM_TREE,
    PALM_TREE_COCONUTS,
    FLOWER_PURPLE,
    FLOWER_RED,
    FLOWER_WHITE,
    BERRY_BUSH,
    BERRY_BUSH_BERRIES,

    SWAMP_TREE_ONE,
    SWAMP_TREE_TWO,
    SWAMP_TREE_THREE,
    SWAMP_TREE_FOUR,
    SWAMP_BULLRUSH_1,
    SWAMP_BULLRUSH_2,
    SWAMP_GRASS_1,
    SWAMP_GRASS_2,
    SWAMP_LILYPAD,

    MAX
};

#undef enum
#undef const
