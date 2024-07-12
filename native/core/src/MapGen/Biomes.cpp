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
    MapVoxelTypes grassVoxFunction(AV::uint8 altitude, AV::uint8 moisture, const ExplorationMapData* mapData){
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
    void grassPlaceObjectsFunction(std::vector<PlacedItemData>& placedItems, const ExplorationMapData* mapData, AV::uint16 x, AV::uint16 y, AV::uint8 altitude, RegionId region, AV::uint8 moisture){
        if(altitude >= mapData->seaLevel + 10){
            if(processRValue(mapData, x, y, moisture >= 150 ? 1 : 6)){
                placedItems.push_back({
                    x, y,
                    region,
                    PlacedItemId::TREE
                });
            }
        }
    }



    static const std::array BIOMES{
        Biome(0, 0),
        Biome(&grassVoxFunction, &grassPlaceObjectsFunction)
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
                targetBiome = BiomeId::NONE;
            }
        }

        return BIOMES[static_cast<size_t>(targetBiome)];
    }

};
