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
    void GRASS_LAND_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture){
        if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, moisture >= 150 ? 1 : 6)){
                PLACE_ITEM(PlacedItemId::TREE);
            }
        }
    }
    //
    //
    MapVoxelTypes GRASS_FOREST_VoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
        return MapVoxelTypes::TREES;
    }
    void GRASS_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture){
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
    void CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture){
        if(altitude < mapData->seaLevel + 10) return;
        if(processRValue(mapData, x, y, 1)){
            PLACE_ITEM(PlacedItemId::CHERRY_BLOSSOM_FOREST);
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

    void NONE_PlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture){
    }
    #undef PLACE_ITEM


    static const std::array BIOMES{
        Biome(0, 0),
        Biome(&GRASS_LAND_VoxFunction, &GRASS_LAND_PlaceObjectsFunction),
        Biome(&GRASS_FOREST_VoxFunction, &GRASS_FOREST_PlaceObjectsFunction),
        Biome(&CHERRY_BLOSSOM_FOREST_VoxFunction, &CHERRY_BLOSSOM_FOREST_PlaceObjectsFunction),
        Biome(&EXP_FIELD_VoxFunction, &NONE_PlaceObjectsFunction),
        Biome(&SHALLOW_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction),
        Biome(&DEEP_OCEAN_VoxFunction, &NONE_PlaceObjectsFunction),
    };

    Biome::Biome(DetermineVoxFunction voxFunction, PlaceObjectFunction placementFunction)
        : mVoxFunction(voxFunction),
        mPlacementFunction(placementFunction) {

    }

    Biome::~Biome(){

    }

    const Biome& Biome::getBiomeForId(RegionType regionId){
        BiomeId targetBiome;
        switch(regionId){
            case RegionType::GRASSLAND: targetBiome = BiomeId::GRASS_LAND; break;
            case RegionType::CHERRY_BLOSSOM_FOREST: targetBiome = BiomeId::CHERRY_BLOSSOM_FOREST; break;
            case RegionType::EXP_FIELDS: targetBiome = BiomeId::EXP_FIELD; break;
            default:{
                targetBiome = BiomeId::GRASS_LAND;
            }
        }

        return BIOMES[static_cast<size_t>(targetBiome)];
    }

};
