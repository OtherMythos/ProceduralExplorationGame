
::EnumDef.addToEnum("PlaceId", @"
    GATEWAY,
    PLAYER_SPAWN,

    GOBLIN_CAMP,
    DUSTMITE_NEST,

    GARRITON,
    MORRINGTON,

    TEMPLE,
    GRAVEYARD,

    CHERRY_BLOSSOM_ORB
");

enum PlaceType{
    NONE,
    GATEWAY,
    PLAYER_SPAWN,
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
