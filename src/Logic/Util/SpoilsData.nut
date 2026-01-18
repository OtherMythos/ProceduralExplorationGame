enum SPOILS_ENTRIES{
    NONE,
    EXP_ORBS,
    COINS,
    SPAWN_ENEMIES,
    DROPPED_ITEMS,
    SINGLE_ENEMY,
    SPAWN_WORLD_EFFECT
};

::SpoilsEntry <- class{
    mType = SPOILS_ENTRIES.NONE;
    mFirst = 0;
    constructor(spoilType, first){
        mType = spoilType;
        mFirst = first;
    }
};