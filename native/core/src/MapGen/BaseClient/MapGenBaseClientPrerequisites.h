#pragma once

#include <vector>
#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    #include "../../../../../src/MapGen/Exploration/Generator/MapConstants.h.nut"

    //#include "../../../../src/Content/PlaceConstants.h.nut"

    static const AV::uint8 MapVoxelColour[] = {
        VOXEL_VALUES
    };
    #undef VOXEL_VALUES

    static const RegionId REGION_ID_WATER = 100;

    class ExplorationMapInputData : public MapGenDataContainer{
    };

    struct FloodFillEntry;

    struct ExplorationMapGenWorkspace{
        std::vector<LandId> landWeighted;
        std::vector<float> additionLayer;
        std::vector<FloodFillEntry*> waterData;
        std::vector<FloodFillEntry*> landData;
        std::vector<WorldPoint> blobSeeds;
    };


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

    class PlaceDef{
    public:
        std::string name;
        std::string desc;
        //PlaceType t;
        float rarity;
        AV::uint32 minLandmass;
        AV::uint8 necessaryFeatures;

        PlaceDef(){
            this->name = "";
            this->desc = "";
            //this->t = PlaceType::NONE;
            this->rarity = 0.0;
            this->minLandmass = 0;
            this->necessaryFeatures = 0;
        }
        PlaceDef(const std::string& name, const std::string& desc, float rarity, AV::uint32 minLandmass = 10, AV::uint8 necessaryFeatures = 0x0){
            this->name = name;
            this->desc = desc;
            //this->t = t;
            this->rarity = rarity;
            this->minLandmass = minLandmass;
            this->necessaryFeatures = necessaryFeatures;
        }
    };


    static size_t mapGenRandomIntMinMax(size_t min, size_t max){
        return min + (RandomWrapper::singleton.rand() % static_cast<size_t>(max - min + 1));
    }
    template<typename T>
    static size_t mapGenRandomIndex(const std::vector<T>& list){
        if(list.empty()) return 0;
        return mapGenRandomIntMinMax(0, list.size()-1);
    }

    static inline WorldPoint findRandomPointInLandmass(const FloodFillEntry* e){
        return e->coords[mapGenRandomIndex(e->coords)];
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

    static void findNeighboursForRegion(const ExplorationMapData* mapData, const RegionData& d, std::set<RegionId>& outRegions){
        for(WorldPoint p : d.edges){
            WorldCoord xp, yp;
            READ_WORLD_POINT(p, xp, yp);

            outRegions.insert(*REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(xp + 1, yp)));
            outRegions.insert(*REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(xp - 1, yp)));
            outRegions.insert(*REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(xp, yp + 1)));
            outRegions.insert(*REGION_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(xp, yp - 1)));
        }

        outRegions.erase(REGION_ID_WATER);
    }

    static void mergeRegionData(ExplorationMapData* mapData, RegionData& d, RegionData& sd){
        assert(d.id != sd.id);
        sd.coords.insert(sd.coords.end(), d.coords.begin(), d.coords.end());
        //As much as it might include the seam, it's still more efficient than re-scanning.
        sd.edges.insert(sd.edges.end(), d.edges.begin(), d.edges.end());

        for(WorldPoint wp : d.coords){
            RegionId* writeRegion = REGION_PTR_FOR_COORD(mapData, wp);
            *writeRegion = sd.id;
        }

        d.total = 0;
        d.coords.clear();
        d.edges.clear();
    }

    static const float BLOB_SIZE = 200;
    static const float HALF_BLOB_SIZE = BLOB_SIZE/2;
    static const float LINE_BOX_SIZE = 50;


}
