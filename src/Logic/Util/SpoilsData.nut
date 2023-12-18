enum SPOILS_ENTRIES{
    NONE,
    EXP_ORBS,
    COINS
};

::SpoilsEntry <- class{
    mType = SPOILS_ENTRIES.NONE;
    mFirst = 0;
    constructor(spoilType, first){
        mType = spoilType;
        mFirst = first;
    }
};