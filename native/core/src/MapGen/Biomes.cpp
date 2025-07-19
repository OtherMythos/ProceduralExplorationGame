#include "Biomes.h"

#include <array>

#include "BaseClient/Steps/PerlinNoise.h"

namespace ProceduralExplorationGameCore{


    bool processRValue(const ExplorationMapData* mapData, AV::uint16 xc, AV::uint16 yc, int R){
        float max = 0;
        int yy = (int)yc;
        int xx = (int)xc;
        // there are more efficient algorithms than this
        for (int dy = -R; dy <= R; dy++) {
            for (int dx = -R; dx <= R; dx++) {
                int xn = dx + xc;
                int yn = dy + yc;
                // optionally check that (dx*dx + dy*dy <= R * (R + 1))
                if (0 <= yn && yn < mapData->height && 0 <= xn && xn < mapData->width) {
                    float e = *(static_cast<float*>(mapData->blueNoiseBuffer) + (xn + yn * mapData->width));
                    if(e > max) {
                        max = e;
                        yy = yn;
                        xx = xn;
                    }
                }
            }
        }

        if((int)xc == xx && (int)yc == yy){
            return true;
        }
        return false;
    }

    #define PLACE_ITEM(XX) placedItems.push_back({x, y, region, XX});
    //
    MapVoxelTypes GRASS_LAND_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        if(altitude >= mapData->seaLevel + 10){
            if(moisture >= mapData->seaLevel + 50){
                return MapVoxelTypes::TREES;
            }else{
                return MapVoxelTypes::DIRT;
            }
        }else{
            return MapVoxelTypes::SAND;
        }
    }
    void GRASS_LAND_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
        //if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, moisture >= 150 ? 1 : 6)){
                if(moisture < 150 && mapGenRandomIntMinMax(0, 3) == 0){
                    static const PlacedItemId VALS[] = {PlacedItemId::FLOWER_RED, PlacedItemId::FLOWER_WHITE, PlacedItemId::FLOWER_PURPLE};
                    size_t val = mapGenRandomIntMinMax(0, 2);
                    PLACE_ITEM(VALS[val]);
                }else if(moisture < 150 && mapGenRandomIntMinMax(0, 3) == 0){
                    PLACE_ITEM(PlacedItemId::BERRY_BUSH_BERRIES);
                }else{
                    bool apple = (mapGenRandomIntMinMax(0, 100) == 0);
                    PLACE_ITEM(apple ? PlacedItemId::TREE_APPLE : PlacedItemId::TREE);
                }
            }
        }
        else if(altitude >= mapData->seaLevel && altitude < mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, 8)){
                PLACE_ITEM(PlacedItemId::PALM_TREE_COCONUTS);
            }
        }
    }
    void NONE_FinalVoxChangeFunction(const ExplorationMapData* mapData, AV::uint32* vox, AV::uint32* secondary, AV::uint16 x, AV::uint16 y){

    }
    //
    //
    MapVoxelTypes GRASS_FOREST_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::TREES;
    }
    void GRASS_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
        //if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        //if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, 1)){
                PLACE_ITEM(PlacedItemId::TREE);
            }
        //}
    }
    //
    //
    MapVoxelTypes CHERRY_BLOSSOM_FOREST_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        if(altitude < mapData->seaLevel + 10) return MapVoxelTypes::SAND;
        return MapVoxelTypes::TREES_CHERRY_BLOSSOM;
    }
    void CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
        //if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        if(altitude < mapData->seaLevel + 10) return;
        if(processRValue(mapData, x, y, 1)){
            PLACE_ITEM(PlacedItemId::CHERRY_BLOSSOM_TREE);
        }
    }
    //
    //
    MapVoxelTypes EXP_FIELD_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        if(altitude < mapData->seaLevel + 10) return MapVoxelTypes::SAND_EXP_FIELD;
        return MapVoxelTypes::DIRT_EXP_FIELD;
    }
    //
    //
    MapVoxelTypes SHALLOW_OCEAN_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::SAND;
    }
    //
    //
    MapVoxelTypes DEEP_OCEAN_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::SAND;
    }
    //
    MapVoxelTypes DESERT_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::SAND;
    }
    void DESERT_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
        //if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        //if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, 12)){
                PLACE_ITEM(PlacedItemId::CACTUS);
            }
        //}
    }

    MapVoxelTypes SWAMP_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        if(moisture >= mapData->seaLevel + 50){
            return MapVoxelTypes::SWAMP_FOREST_GRASS;
        }else{
            return MapVoxelTypes::SWAMP_GRASS;
        }
    }

    void SWAMP_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
        if(altitude < mapData->seaLevel){
            if(regionDistance <= 1){
                if(processRValue(mapData, x, y, 1)){
                    bool plantType = (mapGenRandomIntMinMax(0, 3) == 0);
                    PLACE_ITEM(
                        plantType ?
                        PlacedItemId::SWAMP_GRASS_2 :
                        PlacedItemId::SWAMP_GRASS_1
                    );
                }
            }
            if(regionDistance >= 4){
                if(processRValue(mapData, x, y, 4)){
                    PLACE_ITEM(
                        PlacedItemId::SWAMP_LILYPAD
                    );
                }
            }
            return;
        }

        if(regionDistance >= 12){
            if(processRValue(mapData, x, y, 12)){
                bool treeType = (mapGenRandomIntMinMax(0, 2) == 0);
                PLACE_ITEM(treeType ? PlacedItemId::SWAMP_TREE_ONE : PlacedItemId::SWAMP_TREE_TWO);
                //PLACE_ITEM(PlacedItemId::SWAMP_TREE_TWO);
            }
        }
    }

    template <typename T>
    T mix(const T& a, const T& b, float t) {
        return a * (1.0f - t) + b * t;
    }

    AV::uint8 SWAMP_DetermineAltitudeFunction(AV::uint8 altitude, AV::uint8 moisture, AV::uint8 altitudeDistance, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData){
        PerlinNoise p(100);
        float pv = p.perlin2d(x, y, 0.10, 1);

        static const float DIST = 18.0f;
        float modifier = (altitudeDistance > DIST ? DIST : static_cast<float>(altitudeDistance)) / DIST;
        float originalAltitude = float(altitude);
        float altDifference = originalAltitude - mapData->seaLevel;
        float startAltDifference = 1;
        float fa = mapData->seaLevel + startAltDifference * 0.25 + (pv - 0.5) * 8;
        if(fa > mapData->seaLevel + 1){
            fa = mapData->seaLevel + altDifference * 0.15;
        }
        float a = mix<float>(fa, originalAltitude, 1.0-modifier);
        AV::uint8 out = static_cast<AV::uint8>(a);
        return out;
    }

    void SWAMP_FinalVoxChangeFunction(const ExplorationMapData* mapData, AV::uint32* vox, AV::uint32* secondary, AV::uint16 x, AV::uint16 y){
        *secondary |= DO_NOT_PLACE_RIVERS_VOXEL_FLAG;

        if((*vox & 0xFF) < mapData->seaLevel){
            *secondary |= TEST_CHANGE_WATER_FLAG;
        }
    }

    void NONE_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture, AV::uint8 regionDistance){
    }
    #undef PLACE_ITEM

    AV::uint8 NONE_DetermineAltitudeFunction(AV::uint8 altitude, AV::uint8 moisture, AV::uint8 altitudeDistance, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData){
        return altitude;
    }

    AV::uint8 DESERT_DetermineAltitudeFunction(AV::uint8 altitude, AV::uint8 moisture, AV::uint8 altitudeDistance, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData){
        //float thing = abs(sin(float(x) * 0.1)) * 60 - 20;
        float t = (sin(float(x) * 0.1));
        if(t < 0) t = -t;
        float thing = t * 60 - 20;
        float modifier = (altitudeDistance > 12 ? 12.0 : static_cast<float>(altitudeDistance)) / 12.0;
        float other = float(altitude) + thing * modifier;
        if(other < mapData->seaLevel){
            other = mapData->seaLevel;
        }
        else if(other >= 0xFF){
            other = 0xFF - 1;
        }
        AV::uint8 out = static_cast<AV::uint8>(other);
        return out;
    }

    Biome::BiomeColour NONE_WaterTextureColourChangeFunction(bool mask, AV::uint8 distance, const ExplorationMapData* mapData){
        return {0, 0, 150, 255};
    }

    Biome::BiomeColour SWAMP_WaterTextureColourChangeFunction(bool mask, AV::uint8 distance, const ExplorationMapData* mapData){
        AV::uint8 targetDist = distance >= 4 ? 4 : distance;

        Biome::BiomeColour c{0, 100, 75, 255};
        c.g -= targetDist * 10;
        c.b -= targetDist * 10;
        return c;
    }

    static const std::array BIOMES{
        Biome(0, 0, 0, 0, 0),
        Biome(&GRASS_LAND_VoxFunction, &GRASS_LAND_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&GRASS_FOREST_VoxFunction, &GRASS_FOREST_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&CHERRY_BLOSSOM_FOREST_VoxFunction, &CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&EXP_FIELD_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&DESERT_VoxFunction, &DESERT_PlaceObjectsFunction, &DESERT_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&SWAMP_VoxFunction, &SWAMP_PlaceObjectsFunction, &SWAMP_DetermineAltitudeFunction, &SWAMP_FinalVoxChangeFunction, &SWAMP_WaterTextureColourChangeFunction),
        Biome(&SHALLOW_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
        Biome(&DEEP_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction, &NONE_FinalVoxChangeFunction, &NONE_WaterTextureColourChangeFunction),
    };

    Biome::Biome(DetermineVoxFunction voxFunction, PlaceObjectFunction placementFunction, DetermineAltitudeFunction altitudeFunction, FinalVoxChangeFunction finalVoxFunction, WaterTextureColourFunction waterTexFunction)
        : mVoxFunction(voxFunction),
        mPlacementFunction(placementFunction),
        mAltitudeFunction(altitudeFunction),
        mFinalVoxChangeFunction(finalVoxFunction),
        mWaterTextureColourFunction(waterTexFunction) {

    }

    Biome::~Biome(){

    }

    const Biome& Biome::getBiomeForId(RegionType regionId){
        BiomeId targetBiome;
        switch(regionId){
            case RegionType::GRASSLAND: targetBiome = BiomeId::GRASS_LAND; break;
            case RegionType::CHERRY_BLOSSOM_FOREST: targetBiome = BiomeId::CHERRY_BLOSSOM_FOREST; break;
            case RegionType::EXP_FIELDS: targetBiome = BiomeId::EXP_FIELD; break;
            case RegionType::DESERT: targetBiome = BiomeId::DESERT; break;
            case RegionType::SWAMP: targetBiome = BiomeId::SWAMP; break;
            default:{
                targetBiome = BiomeId::GRASS_LAND;
            }
        }

        return BIOMES[static_cast<size_t>(targetBiome)];
    }

};
