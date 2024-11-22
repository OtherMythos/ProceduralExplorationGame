local Biome = class{
    mSpawnableEnemies = null;
    constructor(spawnableEnemies){
        mSpawnableEnemies = spawnableEnemies;
    }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome([]);

::Biomes[BiomeId.GRASS_LAND] = Biome([EnemyId.GOBLIN]);
::Biomes[BiomeId.GRASS_FOREST] = Biome([EnemyId.GOBLIN]);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome([EnemyId.FOREST_GUARDIAN]);
::Biomes[BiomeId.EXP_FIELD] = Biome([]);
::Biomes[BiomeId.DESERT] = Biome([EnemyId.SKELETON]);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome([EnemyId.SQUID]);
::Biomes[BiomeId.DEEP_OCEAN] = Biome([EnemyId.SQUID]);