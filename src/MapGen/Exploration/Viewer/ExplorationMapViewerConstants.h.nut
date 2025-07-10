#pragma once
#define enum enum class

enum MapViewerDrawOptions{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    MOISTURE_MAP,
    REGIONS,
    REGION_DISTANCE,
    REGION_EDGES,
    BLUE_NOISE,
    RIVER_DATA,
    LAND_GROUPS,
    EDGE_VALS,
    PLAYER_START_POSITION,
    VISIBLE_REGIONS, //NOTE: Generally only used during gameplay.
    REGION_SEEDS,
    PLACE_LOCATIONS,
    VISIBLE_PLACES_MASK,

    MAX
};

#undef enum
