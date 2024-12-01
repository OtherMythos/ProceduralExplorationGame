enum EnemyId{
    NONE
};

//Bitmask to keep track of which types of terrain an enemy can walk on.
enum EnemyTraversableTerrain{
    LAND=0x1,
    WATER=0x2,

    ALL = 0xFF
};

::Enemy <- class{
    mName = null;
    mCharacterModelType = null;
    mDefaultEquippableDef = null;
    mTraversableTerrain = EnemyTraversableTerrain.ALL;
    mAllowSwimState = true;
    constructor(name, characterModelType, defaultEquippableDef=EquippableId.NONE_ATTACK, traversableTerrain=EnemyTraversableTerrain.ALL, allowSwimState=true){
        mName = name;
        mCharacterModelType = characterModelType;
        mTraversableTerrain = traversableTerrain;
        mAllowSwimState = allowSwimState;
        mDefaultEquippableDef = defaultEquippableDef;
    }
    function getName() { return mName; }
    function getModelType() { return mCharacterModelType; }
    function getTraversableTerrain() { return mTraversableTerrain; }
    function getAllowSwimState() { return mAllowSwimState; }
    function getDefaultEquippableDef() { return mDefaultEquippableDef; }
};

::nameToEnemyId <- function(enemyName){
    local testName = enemyName.tolower();
    foreach(c,i in ::Enemies){
        if(i.getName().tolower() == testName){
            return c;
        }
    }

    return EnemyId.NONE;
}