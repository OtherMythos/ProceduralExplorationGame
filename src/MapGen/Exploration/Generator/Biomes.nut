local Biome = class{
    mName = null;
    mSpawnableEnemies = null;
    mSkyColour = null;
    constructor(name, spawnableEnemies, skyColour){
        mName = name;
        mSpawnableEnemies = spawnableEnemies;
        mSkyColour = skyColour;
    }

    function getName() { return mName; }
    function getSkyColour() { return mSkyColour; }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome("None", [], null);

::Biomes[BiomeId.GRASS_LAND] = Biome("Grass Land", [EnemyId.GOBLIN], null);
::Biomes[BiomeId.GRASS_FOREST] = Biome("Grass Forest", [EnemyId.GOBLIN], null);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome("Cherry Blossom Forest", [EnemyId.FOREST_GUARDIAN], null);
::Biomes[BiomeId.EXP_FIELD] = Biome("EXP Field", [], null);
::Biomes[BiomeId.DESERT] = Biome("Desert", [EnemyId.SKELETON], null);
::Biomes[BiomeId.SWAMP] = Biome("Swamp", [EnemyId.GOBLIN], Vec3(0, 0, 0));
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID], null);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID], null);