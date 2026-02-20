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
    "mHealthToDeliver_": 50,
    "mTotalHealth_": 50,
    "mElapsedTime_": 0.0,
    "mParticleSystem_": null,

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
        mParticleSystem_ = particleSystem;

        local centrePos = ::MapGenHelpers.getPositionForPoint(regionData.centrePoint);
        world.mEntityFactory_.constructGenericDescriptionTrigger(centrePos, "hot springs", regionData.radius, 0.5);
    },
    "update": function(world){
        //TODO add hot springs specific logic here
        //print("hot springs ");
    },
    "enter": function(world){
        //Register the hot springs world gen component
        local component = HotSpringsWorldGenComponent(world, this, mParticleSystem_);
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
            script.mStayDormant_ = !active;
        }
    }

    function resetWorms(){
        foreach(script in mWormScripts_){
            script.mStayDormant_ = true;
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
                script1.mStayDormant_ = true;
                component.addWormScript(script1);
            }
            if(script2 != null){
                script2.mStayDormant_ = true;
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

local SandUrnLogic = {
    "mUrnsSpawned_": 0,
    "mUrnChanceMultiplier_": 1,

    "setup": function(regionData, world){
        //Initialize sand urn spawning for this biome
    },

    "update": function(world){
        //Each frame, check if a sand urn should spawn in the desert
        //Urns spawn very rarely on sand - roughly once per 20 seconds at 60 fps
        if(mUrnsSpawned_ >= 3) return;

        local urnChance = _random.randInt(100 * mUrnChanceMultiplier_);
        if(urnChance != 0) return;

        //Find a spawn position
        local playerPos = world.getPlayerPosition();
        local spawnPos = playerPos + (_random.randVec3() - 0.5) * 200;
        spawnPos.y = world.getZForPos(spawnPos);

        //Check if this position is on sand (not water)
        if(::MapGenHelpers.getIsWaterForPosition(world.mMapData_, spawnPos)){
            return;
        }

        //Create the sand urn entity
        local urnEntity = world.mEntityFactory_.constructSandUrn(spawnPos);

        //Get a drift direction towards the player
        local driftDirection = (playerPos - spawnPos);
        driftDirection.y = 0;
        driftDirection.normalise();

        //Assign the drift direction to the urn script
        if(world.getEntityManager().hasComponent(urnEntity, EntityComponents.SCRIPT)){
            local scriptComponent = world.getEntityManager().getComponent(urnEntity, EntityComponents.SCRIPT);
            scriptComponent.mScript.driftDirection = driftDirection;
        }

        //Track this urn and increase difficulty for next one
        mUrnsSpawned_++;
        mUrnChanceMultiplier_ *= 4;
    },

    "enter": function(world){
        //Player entered desert - urns can spawn
    },

    "leave": function(world){
        //Player left desert - reset urn spawning
        mUrnsSpawned_ = 0;
        mUrnChanceMultiplier_ = 1;
    }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.NONE] = Biome("None", [], null, null, null, null);

::Biomes[BiomeId.GRASS_LAND] = Biome("Grass Land", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.GRASS_FOREST] = Biome("Grass Forest", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome("Cherry Blossom Forest", [EnemyId.FOREST_GUARDIAN], null, null, null, null);
::Biomes[BiomeId.EXP_FIELD] = Biome("EXP Field", [], null, null, null, null);
::Biomes[BiomeId.DESERT] = Biome("Desert", [EnemyId.SKELETON], null, null, 2, null, SandUrnLogic);
::Biomes[BiomeId.SWAMP] = Biome("Swamp", [EnemyId.GOBLIN], Vec3(0.05, 0.1, 0.08), Vec3(0.25, 0.25, 0.25), 0.25, Vec2(50, 200));
::Biomes[BiomeId.HOT_SPRINGS] = Biome("Hot Springs", [EnemyId.GOBLIN], null, null, null, null, HotSpringsLogic, false);
::Biomes[BiomeId.MUSHROOM_CLUSTER] = Biome("Mushroom Cluster", [EnemyId.GOBLIN], null, null, null, null, null, false);
::Biomes[BiomeId.GEOTHERMAL_PLANES] = Biome("Geothermal Planes", [EnemyId.GOBLIN], null, null, null, null, GeoThermalLogic);
::Biomes[BiomeId.MUSHROOM_FOREST] = Biome("Mushroom Forest", [EnemyId.GOBLIN], null, null, null, null);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome("Shallow Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.DEEP_OCEAN] = Biome("Deep Ocean", [EnemyId.SQUID], null, null, null, null);
::Biomes[BiomeId.WORM_FIELDS] = Biome("Worm Fields", [], null, null, null, null, WormFieldsLogic);