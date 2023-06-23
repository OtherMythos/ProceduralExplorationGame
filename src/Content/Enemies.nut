enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,

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
    constructor(name, traversableTerrain=EnemyTraversableTerrain.ALL){
        mName = name;
        mTraversableTerrain = traversableTerrain;
    }
    function getName() { return mName; }
    function getTraversableTerrain() { return mTraversableTerrain; }
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = EnemyDef("None");

::Enemies[EnemyId.GOBLIN] = EnemyDef("Goblin");
::Enemies[EnemyId.SQUID] = EnemyDef("Squid", EnemyTraversableTerrain.WATER);