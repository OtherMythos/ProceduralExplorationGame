enum PercentageEncounterEntryType{
    NONE,
    ENEMY,
    EXP
};

::PercentageEncounterData <- class{
    mType = PercentageEncounterEntryType.NONE;
    mAmount = 1;
    mSecondaryType = null;

    constructor(encounterType, amount, secondary){
        mType = encounterType;
        mAmount = amount;
        mSecondaryType = secondary;
    }

    function getDescriptionName(){
        switch(mType){
            case PercentageEncounterEntryType.ENEMY:
                return ::Enemies[mSecondaryType].getName();
            case PercentageEncounterEntryType.EXP:
                return "EXP";
            default:{
                assert(false);
            }
        }
    }

};

::PercentageEncounterHelper <- {

    function getLabelForPercentageDataComponent(comp){
        //assert(comp.mType == SpoilsComponentType.PERCENTAGE);
        return format("%s - %i/%i - %s", comp.mSecond.getDescriptionName(), comp.mFirst, (100-comp.mFirst).tointeger(), comp.mThird.getDescriptionName());
    }

};