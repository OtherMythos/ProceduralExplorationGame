enum EnemyId{
    NONE,

    GOBLIN,
    SQUID,
    CRAB,
    SKELETON,
    FOREST_GUARDIAN,

    MAX
};

::Enemies <- array(EnemyId.MAX, null);

::Enemies[EnemyId.NONE] = Enemy("None", null);

::Enemies[EnemyId.GOBLIN] = Enemy("Goblin", CharacterModelType.GOBLIN);
::Enemies[EnemyId.SQUID] = Enemy("Squid", CharacterModelType.SQUID, EnemyTraversableTerrain.WATER, false);
::Enemies[EnemyId.CRAB] = Enemy("Crab", CharacterModelType.CRAB);
::Enemies[EnemyId.SKELETON] = Enemy("Skeleton", CharacterModelType.SKELETON, EnemyTraversableTerrain.LAND, false);
::Enemies[EnemyId.FOREST_GUARDIAN] = Enemy("Forest Guardian", CharacterModelType.FOREST_GUARDIAN, EnemyTraversableTerrain.LAND, false);