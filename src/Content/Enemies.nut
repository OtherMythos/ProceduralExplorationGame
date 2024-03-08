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
    mTraversableTerrain = EnemyTraversableTerrain.ALL;
    mAllowSwimState = true;
    constructor(name, traversableTerrain=EnemyTraversableTerrain.ALL, allowSwimState=true){
        mName = name;
        mTraversableTerrain = traversableTerrain;
        mAllowSwimState = allowSwimState;
    }
    function getName() { return mName; }
    function getTraversableTerrain() { return mTraversableTerrain; }
    function getAllowSwimState() { return mAllowSwimState; }
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = EnemyDef("None");

::Enemies[EnemyId.GOBLIN] = EnemyDef("Goblin");
::Enemies[EnemyId.SQUID] = EnemyDef("Squid", EnemyTraversableTerrain.WATER, false);
::Enemies[EnemyId.CRAB] = EnemyDef("Crab");
::Enemies[EnemyId.SKELETON] = EnemyDef("Skeleton");