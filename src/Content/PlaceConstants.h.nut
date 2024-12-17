#pragma once
#ifndef WORKAROUND
#define enum enum class
#endif

enum PlaceId{
    NONE,
    GATEWAY,

    GOBLIN_CAMP,
    DUSTMITE_NEST

    /*
    HAUNTED_WELL,
    DARK_CAVE,
    GOBLIN_VILLAGE,
    WIND_SWEPT_BEACH,
    ROTHERFORD,

    CITY_1,
    CITY_2,
    CITY_3,

    TOWN_1,
    TOWN_2,
    TOWN_3,

    VILLAGE_1,
    VILLAGE_2,
    VILLAGE_3,

    LOCATION_1,
    //LOCATION_2,
    //LOCATION_3,
*/

    MAX
};

enum PlaceType{
    NONE,
    GATEWAY,
    CITY,
    TOWN,
    VILLAGE,
    LOCATION,

    MAX
};

//Squirrel doesn't let you shift bits in place :( so this will do fine.
enum PlaceNecessaryFeatures{
    RIVER = 0x1,
    OCEAN = 0x2,
    LAKE = 0x4,
};

#undef enum
