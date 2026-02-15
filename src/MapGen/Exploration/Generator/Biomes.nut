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

local GeoThermalLogic = {
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
    }
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
        world.mEntityFactory_.constructGenericDescriptionTrigger(centrePos, "hot springs", regionData.radius, 0.5);
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

local WormFieldsWorldGenComponent = class{
    mWormScripts_ = [];

    constructor(){
        mWormScripts_ = [];
    }

    function update(){

    }

    function addWormScript(script){
        mWormScripts_.append(script);
    }

    function setWormsActive(active){
        foreach(script in mWormScripts_){
            script.mIsActive_ = active;
        }
    }

    function resetWorms(){
        foreach(script in mWormScripts_){
            script.mCurrentStage_ = 0;
            script.mStageTimer_ = 0;
            script.mIsActive_ = false;
        }
    }
};

local WormFieldsLogic = {
    "mWormFieldsComponentId_": null,

    "setup": function(regionData, world){
        //Spawn 2 giant worms at random points in the region
        local component = WormFieldsWorldGenComponent();

        local points = regionData.coords;
        if(points.len() >= 2){
            //Pick two random points
            local idx1 = _random.randInt(0, points.len());
            local idx2 = _random.randInt(0, points.len());

            local pos1 = ::MapGenHelpers.getPositionForPoint(points[idx1]);
            local pos2 = ::MapGenHelpers.getPositionForPoint(points[idx2]);

            //Construct worms with inactive state
            local worm1 = world.createEnemy(EnemyId.GIANT_WORM, pos1);
            local worm2 = world.createEnemy(EnemyId.GIANT_WORM, pos2);

            //Get the scripts and add them to component
            local manager = world.getEntityManager();
            local script1 = manager.getComponent(worm1.getEID(), EntityComponents.SCRIPT).mScript;
            local script2 = manager.getComponent(worm2.getEID(), EntityComponents.SCRIPT).mScript;

            if(script1 != null){
                script1.mIsActive_ = false;
                component.addWormScript(script1);
            }
            if(script2 != null){
                script2.mIsActive_ = false;
                component.addWormScript(script2);
            }
        }

        mWormFieldsComponentId_ = world.registerWorldComponent(component);
    },

    "update": function(world){
        //TODO add worm fields specific logic here
    },

    "enter": function(world){
        //Player entered worm fields - activate worms
        if(mWormFieldsComponentId_ != null){
            local component = world.getWorldComponent(mWormFieldsComponentId_);
            if(component != null){
                component.setWormsActive(true);
            }
        }
    },

    "leave": function(world){
        //Player left worm fields - reset and deactivate worms
        if(mWormFieldsComponentId_ != null){
            local component = world.getWorldComponent(mWormFieldsComponentId_);
            if(component != null){
                component.resetWorms();
            }
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
::Biomes[BiomeId.GEOTHERMAL_PLANES] = Biome("Geothermal Planes", [EnemyId.GOBLIN], null, null, null, null, GeoThermalLogic);
::Biomes[BiomeId.MUSHROOM_FOREST] = Biome("Mushroom Forest", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.WORM_FIELDS] = Biome("Worm Fields", [], null, null, null, null, WormFieldsLogic);