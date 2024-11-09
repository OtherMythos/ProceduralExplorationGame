#pragma once

#include "System/EnginePrerequisites.h"
#include "GamePrerequisites.h"

#include <vector>
#include <string>

namespace ProceduralExplorationGameCore{

    #include "../../../../src/MapGen/Exploration/Generator/MapConstants.h.nut"

    #include "../../../../src/Content/PlaceConstants.h.nut"

    static const AV::uint8 MapVoxelColour[] = {
        VOXEL_VALUES
    };
    #undef VOXEL_VALUES

    struct RegionData{
        RegionId id;
        AV::uint32 total;
        WorldCoord seedX;
        WorldCoord seedY;
        RegionType type;
        AV::uint8 meta;
        std::vector<WorldPoint> coords;
    };

    struct FloodFillEntry{
        AV::uint32 id;
        AV::uint32 total;
        WorldCoord seedX;
        WorldCoord seedY;
        //AV::uint32 startingVal; //TODO figure out
        bool nextToWorldEdge = false;
        std::vector<WorldPoint> edges;
        std::vector<WorldPoint> coords;
    };

    struct PlacedItemData{
        WorldCoord originX;
        WorldCoord originY;
        RegionId region;
        PlacedItemId type;
    };

    struct PlaceData{
        WorldCoord originX;
        WorldCoord originY;
        RegionId region;
        PlaceId type;
    };

    struct RiverData{
        WorldPoint origin;
        std::vector<WorldPoint> points;
    };

    class PlaceDef{
    public:
        std::string name;
        std::string desc;
        PlaceType t;
        float rarity;
        AV::uint32 minLandmass;
        AV::uint8 necessaryFeatures;

        PlaceDef(){
            this->name = "";
            this->desc = "";
            this->t = PlaceType::NONE;
            this->rarity = 0.0;
            this->minLandmass = 0;
            this->necessaryFeatures = 0;
        }
        PlaceDef(const std::string& name, const std::string& desc, PlaceType t, float rarity, AV::uint32 minLandmass = 10, AV::uint8 necessaryFeatures = 0x0){
            this->name = name;
            this->desc = desc;
            this->t = t;
            this->rarity = rarity;
            this->minLandmass = minLandmass;
            this->necessaryFeatures = necessaryFeatures;
        }
    };

    struct ExplorationMapInputData{
        AV::uint32 width;
        AV::uint32 height;

        AV::uint32 seed;
        AV::uint32 moistureSeed;
        AV::uint32 variationSeed;

        AV::uint32 numRivers;
        AV::uint32 numRegions;
        AV::uint8 seaLevel;

        AV::uint16 placeFrequency[(size_t)PlaceType::MAX];
    };

    struct ExplorationMapData{
        AV::uint32 width;
        AV::uint32 height;

        AV::uint32 seed;
        AV::uint32 moistureSeed;
        AV::uint32 variationSeed;

        AV::uint32 seaLevel;

        WorldPoint playerStart;
        WorldPoint gatewayPosition;

        void* voxelBuffer;
        void* secondaryVoxelBuffer;
        void* blueNoiseBuffer;
        size_t voxelBufferSize;
        size_t secondaryVoxelBufferSize;
        size_t blueNoiseBufferSize;
        void* riverBuffer;

        std::vector<RegionData> regionData;
        std::vector<PlacedItemData> placedItems;
        //TODO switch these to not be pointers.
        std::vector<FloodFillEntry*> waterData;
        std::vector<FloodFillEntry*> landData;
        std::vector<PlaceData> placeData;
        std::vector<RiverData> riverData;

        struct BufferData{
            size_t size;
            size_t voxel;
            size_t secondaryVoxel;
            size_t blueNoise;
            size_t river;
        };
        void calculateBuffer(BufferData* buf){
            size_t voxTotal = width * height;
            buf->voxel = 0;
            buf->size += voxTotal * sizeof(AV::uint32);
            buf->secondaryVoxel = buf->size;
            buf->size += voxTotal * sizeof(AV::uint32);
            buf->blueNoise = buf->size;
        }
    };

    struct ExplorationMapGenWorkspace{
        std::vector<LandId> landWeighted;
        std::vector<float> additionLayer;
        std::vector<FloodFillEntry*> waterData;
        std::vector<FloodFillEntry*> landData;
        std::vector<WorldPoint> blobSeeds;
    };

    static inline WorldPoint WRAP_WORLD_POINT(WorldCoord x, WorldCoord y){
        return (static_cast<WorldPoint>(x) << 16) | y;
    }

    static inline void READ_WORLD_POINT(WorldPoint point, WorldCoord& xx, WorldCoord& yy){
        xx = (point >> 16) & 0xFFFF;
        yy = point & 0xFFFF;
    }

    static inline WorldPoint findRandomPointInLandmass(const FloodFillEntry* e){
        //NOTE Build this in with proper isolated random functions in future to prevent differentiators on the seeds.
        size_t idx = 0 + (rand() % static_cast<int>(e->coords.size() - 0 + 1));

        return e->coords[idx];
    }

    template<typename T=AV::uint32*, typename D=ExplorationMapData*>
    static inline T FULL_PTR_FOR_COORD(D mapData, WorldPoint p){
        WorldCoord xx;
        WorldCoord yy;
        READ_WORLD_POINT(p, xx, yy);
        return (reinterpret_cast<T>(mapData->voxelBuffer) + xx + yy * mapData->height);
    }
    template<typename T=AV::uint32*, typename D=ExplorationMapData>
    static inline T FULL_PTR_FOR_COORD_SECONDARY(D mapData, WorldPoint p){
        WorldCoord xx;
        WorldCoord yy;
        READ_WORLD_POINT(p, xx, yy);
        return (reinterpret_cast<T>(mapData->secondaryVoxelBuffer) + xx + yy * mapData->height);
    }

    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD<AV::uint32*, D>(mapData, p)) + N;
    }
    template<typename T, typename D, int N>
    static inline T UINT8_PTR_FOR_COORD_SECONDARY(D mapData, WorldPoint p){
        return reinterpret_cast<T>(FULL_PTR_FOR_COORD_SECONDARY<AV::uint32*, D>(mapData, p)) + N;
    }

    static inline AV::uint8* VOX_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 0>(mapData, p);
    }
    static inline AV::uint8* WATER_GROUP_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 2>(mapData, p);
    }
    static inline AV::uint8* LAND_GROUP_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<AV::uint8*, ExplorationMapData*, 3>(mapData, p);
    }
    //Const
    static inline const AV::uint8* VOX_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 0>(mapData, p);
    }
    static inline const AV::uint8* WATER_GROUP_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 2>(mapData, p);
    }
    static inline const AV::uint8* LAND_GROUP_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD<const AV::uint8*, const ExplorationMapData*, 3>(mapData, p);
    }

    static inline AV::uint8* REGION_PTR_FOR_COORD(ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<AV::uint8*, ExplorationMapData*, 1>(mapData, p);
    }
    static inline const AV::uint8* REGION_PTR_FOR_COORD_CONST(const ExplorationMapData* mapData, WorldPoint p){
        return UINT8_PTR_FOR_COORD_SECONDARY<const AV::uint8*, const ExplorationMapData*, 1>(mapData, p);
    }

    static size_t mapGenRandomIntMinMax(size_t min, size_t max){
        return min + (rand() % static_cast<size_t>(max - min + 1));
    }
    template<typename T>
    static size_t mapGenRandomIndex(const std::vector<T>& list){
        if(list.empty()) return 0;
        return mapGenRandomIntMinMax(0, list.size()-1);
    }
    static LandId findRandomLandmassForSize(const std::vector<FloodFillEntry*>& landData, const std::vector<LandId>& landWeighted, AV::uint32 size){
        if(landData.empty()) return INVALID_LAND_ID;
        //To avoid infinite loops.
        for(int i = 0; i < 100; i++){
            size_t randIndex = mapGenRandomIndex<LandId>(landWeighted);
            LandId idx = landWeighted[randIndex];
            if(landData[idx]->total >= size){
                return idx;
            }
        }
        return INVALID_LAND_ID;
    }

    static LandId findBiggestFloodEntry(const std::vector<FloodFillEntry*>& landData){
        AV::uint32 biggest = 0;
        LandId idx = INVALID_LAND_ID;
        LandId count = 0;
        for(const FloodFillEntry* e : landData){
            if(e->total > biggest){
                biggest = e->total;
                idx = count;
            }
            count++;
        }
        return idx;
    }

    static const float BLOB_SIZE = 200;
    static const float HALF_BLOB_SIZE = BLOB_SIZE/2;
    static const float LINE_BOX_SIZE = 50;

}
