local Biome = class{
    mName = null;
    mSpawnableEnemies = null;
    mSkyColour = null;
    mAmbientModifier = null;
    mLightModifier = null;
    mFogStartEnd = null;
    constructor(name, spawnableEnemies, skyColour, ambientModifier, lightModifier, fogStartEnd){
        mName = name;
        mSpawnableEnemies = spawnableEnemies;
        mSkyColour = skyColour;
        mAmbientModifier = ambientModifier;
        mLightModifier = lightModifier;
        mFogStartEnd = fogStartEnd;
    }

    function getName() { return mName; }
    function getSkyColour() { return mSkyColour; }
    function getAmbientModifier() { return mAmbientModifier; }
    function getLightModifier() { return mLightModifier; }
    function getFogStartEnd() { return mFogStartEnd; }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome("None", [], null, null, null, null);

::Biomes[BiomeId.GRASS_LAND] = Biome("Grass Land", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.GRASS_FOREST] = Biome("Grass Forest", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome("Cherry Blossom Forest", [EnemyId.FOREST_GUARDIAN], null, null, null, null);
::Biomes[BiomeId.EXP_FIELD] = Biome("EXP Field", [], null, null, null, null);
::Biomes[BiomeId.DESERT] = Biome("Desert", [EnemyId.SKELETON], null, null, 2, null);
::Biomes[BiomeId.SWAMP] = Biome("Swamp", [EnemyId.GOBLIN], Vec3(0.05, 0.1, 0.08), Vec3(0.25, 0.25, 0.25), 0.25, Vec2(50, 200));
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID], null, null, null, null);