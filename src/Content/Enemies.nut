enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,

    MAX
};

//Bitmask to keep track of which types of terrain an enemy can walk on.
enum EnemyTraversableTerrain{
    LAND=0x1,
    WATER=0x2,

    ALL = 0xFF
};

local EnemyDef = class{
    mName = null;
    mCharacterModelType = null;
    mTraversableTerrain = EnemyTraversableTerrain.ALL;
    mAllowSwimState = true;
    constructor(name, characterModelType, traversableTerrain=EnemyTraversableTerrain.ALL, allowSwimState=true){
        mName = name;
        mCharacterModelType = characterModelType;
        mTraversableTerrain = traversableTerrain;
        mAllowSwimState = allowSwimState;
    }
    function getName() { return mName; }
    function getModelType() { return mCharacterModelType; }
    function getTraversableTerrain() { return mTraversableTerrain; }
    function getAllowSwimState() { return mAllowSwimState; }
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = EnemyDef("None", null);

::Enemies[EnemyId.GOBLIN] = EnemyDef("Goblin", CharacterModelType.GOBLIN);
::Enemies[EnemyId.SQUID] = EnemyDef("Squid", CharacterModelType.SQUID, EnemyTraversableTerrain.WATER, false);
::Enemies[EnemyId.CRAB] = EnemyDef("Crab", CharacterModelType.CRAB);
::Enemies[EnemyId.SKELETON] = EnemyDef("Skeleton", CharacterModelType.SKELETON, EnemyTraversableTerrain.LAND, false);