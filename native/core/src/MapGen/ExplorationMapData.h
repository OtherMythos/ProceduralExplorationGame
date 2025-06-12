#pragma once

#include <map>
#include <vector>
#include <cassert>

#include "GamePrerequisites.h"

namespace ProceduralExplorationGameCore{



//TODO move this out when I can

#include "../../../../src/MapGen/Exploration/Generator/MapConstants.h.nut"

//#include "../../../../src/Content/PlaceConstants.h.nut"

static const AV::uint8 MapVoxelColour[] = {
    VOXEL_VALUES
};
#undef VOXEL_VALUES

static const RegionId REGION_ID_WATER = 100;

struct RegionData{
    RegionId id;
    AV::uint32 total;
    WorldCoord seedX;
    WorldCoord seedY;
    RegionType type;
    AV::uint8 meta;
    std::vector<WorldPoint> coords;
    std::vector<WorldPoint> edges;
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

struct RiverData{
    WorldPoint origin;
    std::vector<WorldPoint> points;
};
//




    enum class MapDataEntryType{
        ANY,

        UINT32,
        WORLD_POINT,
        VOID_PTR,
        SIZE_TYPE
    };
    union MapDataEntryValue{
        AV::uint32 uint32;
        WorldPoint worldPoint;
        void* ptr;
        size_t size;
    };
    enum class MapDataReadResult{
        SUCCESS,
        TYPE_MISMATCH,
        NOT_FOUND
    };

    struct MapDataEntry{
        MapDataEntryType type;
        MapDataEntryValue value;
    };

    #define MAP_ASSERT_RESULT(XX) \
        MapDataReadResult __mapError = XX; \
        assert(__mapError == MapDataReadResult::SUCCESS);

    class ExplorationMapDataBase{
    private:
        std::map<std::string, MapDataEntry> mEntries;
    public:

        //TODO switch all the strings to references.
        MapDataReadResult readEntry(std::string name, MapDataEntry* outEntry, MapDataEntryType expectedType = MapDataEntryType::ANY) const;

        void setEntry(std::string name, MapDataEntry entry);

        AV::uint32 uint32(std::string name) const;
        void uint32(std::string name, AV::uint32 val);

        size_t sizeType(std::string name) const;
        void sizeType(std::string name, size_t val);

        void* voidPtr(std::string name) const;
        void voidPtr(std::string name, void* val);

        template <typename T>
        T* ptr(std::string name){
            MapDataEntry out;
            MAP_ASSERT_RESULT(readEntry(name, &out, MapDataEntryType::VOID_PTR));

            return reinterpret_cast<T*>(out.value.ptr);
        }

        WorldPoint worldPoint(std::string name) const;
        void worldPoint(std::string name, WorldPoint val);
    };

    class ExplorationMapData : public ExplorationMapDataBase{

    public:




        AV::uint32 width;
        AV::uint32 height;

        //AV::uint32 seed;
        //AV::uint32 moistureSeed;
        //AV::uint32 variationSeed;

        AV::uint32 seaLevel;

        //WorldPoint playerStart;
        //WorldPoint gatewayPosition;

        void* voxelBuffer;
        void* secondaryVoxelBuffer;
        void* blueNoiseBuffer;
        //size_t voxelBufferSize;
        //size_t secondaryVoxelBufferSize;
        //size_t blueNoiseBufferSize;
        //void* riverBuffer;

        //float* waterTextureBuffer;
        //float* waterTextureBufferMask;

        //std::vector<RegionData> regionData;
        std::vector<PlacedItemData> placedItems;
        //TODO switch these to not be pointers.
        std::vector<FloodFillEntry*> waterData;
        std::vector<FloodFillEntry*> landData;
        //std::vector<PlaceData> placeData;
        std::vector<RiverData> riverData;
    };
}
