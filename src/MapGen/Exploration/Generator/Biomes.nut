local Biome = class{
    determineVoxFunction = null;
    placeObjectsFunction = null;
    constructor(determineVoxFunction, placeObjectsFunction){
        this.determineVoxFunction = determineVoxFunction;
        this.placeObjectsFunction = placeObjectsFunction;
    }

    function processRValue(noise, xc, yc, width, height, R){
        local max = 0;
        local yy = yc;
        local xx = xc;
        // there are more efficient algorithms than this
        for (local dy = -R; dy <= R; dy++) {
            for (local dx = -R; dx <= R; dx++) {
                local xn = dx + xc;
                local yn = dy + yc;
                // optionally check that (dx*dx + dy*dy <= R * (R + 1))
                if (0 <= yn && yn < height && 0 <= xn && xn < width) {
                    noise.seek((xn + yn * width) * 4);
                    local e = noise.readn('f');
                    if(e > max) {
                        max = e;
                        yy = yn;
                        xx = xn;
                    }
                }
            }
        }

        if(xc == xx && yc == yy){
            return true;
        }
        return false;
    }
};

::Biomes <- array(BiomeId.MAX, null);

::Biomes[BiomeId.GRASS_LAND] = Biome(
    function(altitude, moisture){
        if(altitude >= 110){
            if(moisture >= 150){
                return MapVoxelTypes.TREES;
            }else{
                return MapVoxelTypes.DIRT;
            }
        }else{
            return MapVoxelTypes.SAND;
        }
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){
        //Don't place trees on the sand.
        if(altitude >= 110){
            if(flags & MapVoxelTypes.RIVER) return;
            if(processRValue(noise, x, y, width, height, moisture >= 150 ? 1 : 6)){
                placementItems.append({
                    "originX": x,
                    "originY": y,
                    "originWrapped": x << 16 | y,
                    "region": region,
                    "type": PlacedItemId.TREE
                });
            }
        }
    }
);
::Biomes[BiomeId.GRASS_FOREST] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.TREES;
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){
        if(flags & MapVoxelTypes.RIVER) return;
        if(processRValue(noise, x, y, width, height, 1)){
            placementItems.append({
                "originX": x,
                "originY": y,
                "originWrapped": x << 16 | y,
                "region": region,
                "type": PlacedItemId.TREE
            });
        }
    }
);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome(
    function(altitude, moisture){
        if(altitude < 110) return MapVoxelTypes.SAND;
        return MapVoxelTypes.TREES_CHERRY_BLOSSOM;
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){
        if(altitude < 110) return;
        if(flags & MapVoxelTypes.RIVER) return;
        if(processRValue(noise, x, y, width, height, 1)){
            placementItems.append({
                "originX": x,
                "originY": y,
                "originWrapped": x << 16 | y,
                "region": region,
                "type": PlacedItemId.CHERRY_BLOSSOM_TREE
            });
        }
    }
);
::Biomes[BiomeId.EXP_FIELD] = Biome(
    function(altitude, moisture){
        if(altitude < 110) return MapVoxelTypes.SAND_EXP_FIELD;
        return MapVoxelTypes.DIRT_EXP_FIELD;
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){
    }
);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.SAND;
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){

    }
);
::Biomes[BiomeId.DEEP_OCEAN] = Biome(
    function(altitude, moisture){
        return MapVoxelTypes.SAND;
    },
    function(placementItems, noise, x, y, width, height, altitude, region, flags, moisture, data){

    }
);