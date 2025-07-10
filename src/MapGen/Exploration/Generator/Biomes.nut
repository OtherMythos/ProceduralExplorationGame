local Biome = class{
    mName = null;
    mSpawnableEnemies = null;
    constructor(name, spawnableEnemies){
        mName = name;
        mSpawnableEnemies = spawnableEnemies;
    }

    function getName() { return mName; }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome("None", []);

::Biomes[BiomeId.GRASS_LAND] = Biome("Grass Land", [EnemyId.GOBLIN]);
::Biomes[BiomeId.GRASS_FOREST] = Biome("Grass Forest", [EnemyId.GOBLIN]);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome("Cherry Blossom Forest", [EnemyId.FOREST_GUARDIAN]);
::Biomes[BiomeId.EXP_FIELD] = Biome("EXP Field", []);
::Biomes[BiomeId.DESERT] = Biome("Desert", [EnemyId.SKELETON]);
::Biomes[BiomeId.SWAMP] = Biome("Swamp", [EnemyId.GOBLIN]);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID]);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID]);