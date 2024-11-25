enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,
    FOREST_GUARDIAN,
    BEE,

    MAX
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = Enemy("None", null);

::Enemies[EnemyId.GOBLIN] = Enemy("Goblin", CharacterModelType.GOBLIN, EquippableId.BARE_HANDS);
::Enemies[EnemyId.SQUID] = Enemy("Squid", CharacterModelType.SQUID, EquippableId.NONE, EnemyTraversableTerrain.WATER, false);
::Enemies[EnemyId.CRAB] = Enemy("Crab", CharacterModelType.CRAB);
::Enemies[EnemyId.SKELETON] = Enemy("Skeleton", CharacterModelType.SKELETON, EquippableId.BARE_HANDS, EnemyTraversableTerrain.LAND, false);
::Enemies[EnemyId.FOREST_GUARDIAN] = Enemy("Forest Guardian", CharacterModelType.FOREST_GUARDIAN, EquippableId.BARE_HANDS, EnemyTraversableTerrain.LAND, false);
::Enemies[EnemyId.BEE] = Enemy("Bee", CharacterModelType.BEE, EquippableId.NONE, EnemyTraversableTerrain.ALL, false);