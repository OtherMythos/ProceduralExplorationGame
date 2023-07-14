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
    function(altitude){
        if(altitude >= 110){
            return MapVoxelTypes.DIRT;
        }else{
            return MapVoxelTypes.SAND;
        }
    },
    function(placementItems, noise, x, y, width, height, altitude, flags){
        //Don't place trees on the sand.
        if(altitude >= 110){
            if(flags & MapVoxelTypes.RIVER) return;
            if(processRValue(noise, x, y, width, height, 6)){
                printf("Placing tree %i, %i", x, y);
                placementItems.append({
                    "originX": x,
                    "originY": y,
                    "originWrapped": x << 16 | y,
                    "type": PlacedItemId.TREE
                });
            }
        }
    }
);
::Biomes[BiomeId.GRASS_FOREST] = Biome(
    function(altitude){
        return MapVoxelTypes.TREES;
    },
    function(placementItems, noise, x, y, width, height, altitude, flags){
        if(flags & MapVoxelTypes.RIVER) return;
        if(processRValue(noise, x, y, width, height, 1)){
            printf("Placing tree %i, %i", x, y);
            placementItems.append({
                "originX": x,
                "originY": y,
                "originWrapped": x << 16 | y,
                "type": PlacedItemId.TREE
            });
        }
    }
);
::Biomes[BiomeId.CHERRY_BLOSSOM_FOREST] = Biome(
    function(altitude){
        return MapVoxelTypes.TREES_CHERRY_BLOSSOM;
    },
    function(placementItems, noise, x, y, width, height, altitude, flags){
        if(flags & MapVoxelTypes.RIVER) return;
        if(processRValue(noise, x, y, width, height, 1)){
            placementItems.append({
                "originX": x,
                "originY": y,
                "originWrapped": x << 16 | y,
                "type": PlacedItemId.CHERRY_BLOSSOM_TREE
            });
        }
    }
);
::Biomes[BiomeId.SHALLOW_OCEAN] = Biome(
    function(altitude){
        return MapVoxelTypes.SAND;
    },
    function(placementItems, noise, x, y, width, height, altitude, flags){

    }
);
::Biomes[BiomeId.DEEP_OCEAN] = Biome(
    function(altitude){
        return MapVoxelTypes.SAND;
    },
    function(placementItems, noise, x, y, width, height, altitude, flags){

    }
);