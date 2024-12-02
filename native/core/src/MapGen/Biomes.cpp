#include "Biomes.h"

#include <array>

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
    void GRASS_LAND_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture){
        if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, moisture >= 150 ? 1 : 6)){
                bool apple = (mapGenRandomIntMinMax(0, 100) == 0);
                PLACE_ITEM(apple ? PlacedItemId::TREE_APPLE : PlacedItemId::TREE);
            }
        }
    }
    //
    //
    MapVoxelTypes GRASS_FOREST_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::TREES;
    }
    void GRASS_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture){
        if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
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
    void CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture){
        if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
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
    void DESERT_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture){
        if(flags & static_cast<AV::uint8>(MapVoxelTypes::RIVER)) return;
        //if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, 12)){
                PLACE_ITEM(PlacedItemId::CACTUS);
            }
        //}
    }

    void NONE_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 flags, AV::uint8 moisture){
    }
    #undef PLACE_ITEM

    AV::uint8 NONE_DetermineAltitudeFunction(AV::uint8 altitude, AV::uint8 moisture, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData){
        return altitude;
    }

    AV::uint8 DESERT_DetermineAltitudeFunction(AV::uint8 altitude, AV::uint8 moisture, AV::uint16 x, AV::uint16 y, const ExplorationMapData* mapData){
        //float thing = abs(sin(float(x) * 0.1)) * 60 - 20;
        float t = (sin(float(x) * 0.1));
        if(t < 0) t = -t;
        float thing = t * 60 - 20;
        float other = float(altitude) + thing;
        if(other < mapData->seaLevel){
            other = mapData->seaLevel;
        }
        else if(other >= 0xFF){
            other = 0xFF - 1;
        }
        AV::uint8 out = static_cast<AV::uint8>(other);
        return out;
    }

    static const std::array BIOMES{
        Biome(0, 0, 0),
        Biome(&GRASS_LAND_VoxFunction, &GRASS_LAND_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
        Biome(&GRASS_FOREST_VoxFunction, &GRASS_FOREST_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
        Biome(&CHERRY_BLOSSOM_FOREST_VoxFunction, &CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
        Biome(&EXP_FIELD_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
        Biome(&DESERT_VoxFunction, &DESERT_PlaceObjectsFunction, &DESERT_DetermineAltitudeFunction),
        Biome(&SHALLOW_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
        Biome(&DEEP_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction, &NONE_DetermineAltitudeFunction),
    };

    Biome::Biome(DetermineVoxFunction voxFunction, PlaceObjectFunction placementFunction, DetermineAltitudeFunction altitudeFunction)
        : mVoxFunction(voxFunction),
        mPlacementFunction(placementFunction),
        mAltitudeFunction(altitudeFunction) {

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
            default:{
                targetBiome = BiomeId::GRASS_LAND;
            }
        }

        return BIOMES[static_cast<size_t>(targetBiome)];
    }

};
