local Biome = class{
    mName = null;
    mSpawnableEnemies = null;
    mSkyColour = null;
    mAmbientModifier = null;
    mLightModifier = null;
    mFogStartEnd = null;
    mBiomeLogic = null;
    mShowDiscoveredPopup = null;
    constructor(name, spawnableEnemies, skyColour, ambientModifier, lightModifier, fogStartEnd, biomeLogic=null, showDiscoveredPopup=true){
        mName = name;
        mSpawnableEnemies = spawnableEnemies;
        mSkyColour = skyColour;
        mAmbientModifier = ambientModifier;
        mLightModifier = lightModifier;
        mFogStartEnd = fogStartEnd;
        mBiomeLogic = biomeLogic;
        mShowDiscoveredPopup = showDiscoveredPopup;
    }

    function getName() { return mName; }
    function getSkyColour() { return mSkyColour; }
    function getAmbientModifier() { return mAmbientModifier; }
    function getLightModifier() { return mLightModifier; }
    function getFogStartEnd() { return mFogStartEnd; }
    function getBiomeLogic() { return mBiomeLogic; }
    function getShowDiscoveredPopup() { return mShowDiscoveredPopup; }
};

local HotSpringsLogic = {
    "mHotSpringsComponentId_": null,

    "setup": function(regionData, world){
        local outPoints = [];
        foreach(p in regionData.coords){
            if(::currentNativeMapData.getIsWaterForPoint(p)){
                outPoints.append(p);
            }
        }
        if(outPoints.len() == 0) return;

        local particleSystemNode = world.mParentNode_.createChildSceneNode(_SCENE_DYNAMIC);
        local particleSystem = _scene.createParticleSystem("hotSpringsWater");
        particleSystemNode.attachObject(particleSystem);
        particleSystemNode.setPosition(0, 0, 0);
        particleSystemNode.setScale(600, 1, 600);

        _gameCore.setupParticleEmitterPoints(particleSystem, outPoints);

        local centrePos = ::MapGenHelpers.getPositionForPoint(regionData.centrePoint);
        world.mEntityFactory_.constructGenericDescriptionTrigger(centrePos, "hot springs", regionData.radius);
    },
    "update": function(world){
        //TODO add hot springs specific logic here
        //print("hot springs ");
    },
    "enter": function(world){
        //Register the hot springs world gen component
        local component = HotSpringsWorldGenComponent(world);
        mHotSpringsComponentId_ = world.registerWorldComponent(component);
    },
    "leave": function(world){
        //Unregister the hot springs world gen component
        if(mHotSpringsComponentId_ != null){
            world.unregisterWorldComponent(mHotSpringsComponentId_);
            mHotSpringsComponentId_ = null;
        }
    }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome("None", [], null, null, null, null);

::Biomes[BiomeId.GRASS_LAND] = Biome("Grass Land", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.GRASS_FOREST] = Biome("Grass Forest", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome("Cherry Blossom Forest", [EnemyId.FOREST_GUARDIAN], null, null, null, null);
::Biomes[BiomeId.EXP_FIELD] = Biome("EXP Field", [], null, null, null, null);
::Biomes[BiomeId.DESERT] = Biome("Desert", [EnemyId.SKELETON], null, null, 2, null);
::Biomes[BiomeId.SWAMP] = Biome("Swamp", [EnemyId.GOBLIN], Vec3(0.05, 0.1, 0.08), Vec3(0.25, 0.25, 0.25), 0.25, Vec2(50, 200));
::Biomes[BiomeId.HOT_SPRINGS] = Biome("Hot Springs", [EnemyId.GOBLIN], null, null, null, null, HotSpringsLogic, false);
::Biomes[BiomeId.MUSHROOM_CLUSTER] = Biome("Mushroom Cluster", [EnemyId.GOBLIN], null, null, null, null, null, false);
::Biomes[BiomeId.GEOTHERMAL_PLANES] = Biome("Geothermal Planes", [EnemyId.GOBLIN], null, null, null, null, HotSpringsLogic, false);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID], null, null, null, null);