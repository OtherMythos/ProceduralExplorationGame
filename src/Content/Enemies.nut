enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,

    MAX
};

local EnemyDef = class{
    mName = null;
    constructor(name){
        mName = name;
    }
    function getName() { return mName; }
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = EnemyDef("None");

::Enemies[EnemyId.GOBLIN] = EnemyDef("Goblin");
::Enemies[EnemyId.SQUID] = EnemyDef("Squid");