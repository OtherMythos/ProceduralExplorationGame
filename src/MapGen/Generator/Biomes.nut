local Biome = class{
    determineVoxFunction = null;
    constructor(determineVoxFunction){
        this.determineVoxFunction = determineVoxFunction;
    }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.GRASS_LAND] = Biome(
    function(altitude, moisture){
        if(altitude >= 110){
            return MapVoxelTypes.DIRT;
        }else{
            return MapVoxelTypes.SAND;
        }
    }
);
::Biomes[BiomeId.GRASS_FOREST] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.TREES;
    }
);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.SAND;
    }
);
::Biomes[BiomeId.DEEP_OCEAN] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.SAND;
    }
);