enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,
    FOREST_GUARDIAN,
    BEE,
    BEE_HIVE,

    MAX
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = Enemy("None", ::EnemyStats(10), null);

::Enemies[EnemyId.GOBLIN] = Enemy("Goblin", ::EnemyStats(100), CharacterModelType.GOBLIN, EquippableId.BARE_HANDS);
::Enemies[EnemyId.SQUID] = Enemy("Squid", ::EnemyStats(100), CharacterModelType.SQUID, EquippableId.NONE, EnemyTraversableTerrain.WATER, false);
::Enemies[EnemyId.CRAB] = Enemy("Crab", ::EnemyStats(100), CharacterModelType.CRAB);
::Enemies[EnemyId.SKELETON] = Enemy("Skeleton", ::EnemyStats(100), CharacterModelType.SKELETON, EquippableId.BARE_HANDS, EnemyTraversableTerrain.LAND, false);
::Enemies[EnemyId.FOREST_GUARDIAN] = Enemy("Forest Guardian", ::EnemyStats(200), CharacterModelType.FOREST_GUARDIAN, EquippableId.BARE_HANDS, EnemyTraversableTerrain.LAND, false);
::Enemies[EnemyId.BEE] = Enemy("Bee", ::EnemyStats(70), CharacterModelType.BEE, EquippableId.NONE_ATTACK, EnemyTraversableTerrain.ALL, false);
::Enemies[EnemyId.BEE_HIVE] = Enemy("Bee Hive", ::EnemyStats(400), CharacterModelType.NONE, EquippableId.NONE, EnemyTraversableTerrain.ALL, false);