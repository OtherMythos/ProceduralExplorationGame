enum EnemyId{
    NONE
};

//Bitmask to keep track of which types of terrain an enemy can walk on.
enum EnemyTraversableTerrain{
    LAND=0x1,
    WATER=0x2,

    ALL = 0xFF
};

//TODO write a test to ensure the player stops attacking after a variety of circumstances.
::Enemy <- class{
    mName = null;
    mCharacterModelType = null;
    mDefaultEquippableDef = null;
    mTraversableTerrain = EnemyTraversableTerrain.ALL;
    mAllowSwimState = true;
    constructor(name, characterModelType, defaultEquippableDef=EquippableId.NONE, traversableTerrain=EnemyTraversableTerrain.ALL, allowSwimState=true){
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
