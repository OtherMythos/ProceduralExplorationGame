#pragma once

#include <vector>
#include <algorithm>
#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    #include "../../../../../src/MapGen/Exploration/Generator/MapConstants.h.nut"

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
        AV::uint8 concavity;
        AV::uint8 placeCount;
        std::vector<WorldPoint> coords;
        std::vector<WorldPoint> edges;
        WorldPoint deepestPoint;
        AV::uint8 deepestDistance;
        WorldPoint centrePoint;
        float radius;
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

    struct PathSegment{
        WorldPoint origin;
        std::vector<WorldPoint> points;
        std::vector<WorldPoint> pointsExpanded;
        AV::uint8 pathId;
        AV::uint8 difficulty;
        AV::uint16 width;
        RegionId region;
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
        sd.edges.insert(sd.edges.end(), d.edges.begin(), d.edges.end());

        for(WorldPoint wp : d.coords){
            RegionId* writeRegion = REGION_PTR_FOR_COORD(mapData, wp);
            *writeRegion = sd.id;
        }

        //Determine the new edges
        //Write the temporary values into d and move them over when done.
        d.edges.clear();
        for(WorldPoint wp : sd.edges){
            WorldCoord x, y;
            READ_WORLD_POINT(wp, x, y);
            std::vector<WorldPoint> neighbors = {
                WRAP_WORLD_POINT(x + 1, y),
                WRAP_WORLD_POINT(x - 1, y),
                WRAP_WORLD_POINT(x, y + 1),
                WRAP_WORLD_POINT(x, y - 1)
            };

            bool same = true;
            for(WorldPoint checkPoint : neighbors){
                const RegionId* region = REGION_PTR_FOR_COORD_CONST(mapData, checkPoint);
                if(*region != sd.id){
                    same = false;
                    break;
                }
            }
            if(!same){
                d.edges.push_back(wp);
            }
        }

        sd.edges = std::move(d.edges);
        d.total = 0;
        d.coords.clear();
        d.edges.clear();
    }

    static void removePointFromCoords(){

    }

    static void setRegionForPoint(ExplorationMapData* mapData, WorldPoint point, RegionId newRegion){
        RegionId* regionPtr = REGION_PTR_FOR_COORD(mapData, point);

        RegionId oldRegion = *regionPtr;
        if(oldRegion == newRegion){
            return;
        }

        std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));
        *regionPtr = newRegion;
        if(newRegion != INVALID_REGION_ID && newRegion != REGION_ID_WATER){
            regionData[newRegion].coords.push_back(point);
        }

        if(oldRegion == INVALID_REGION_ID || oldRegion == REGION_ID_WATER){
            return;
        }

        std::vector<WorldPoint>& coords = regionData[oldRegion].coords;
        auto it = std::find(coords.begin(), coords.end(), point);
        assert(it != coords.end());
        coords.erase(it);
    }

    static const float BLOB_SIZE = 200;
    static const float HALF_BLOB_SIZE = BLOB_SIZE/2;
    static const float LINE_BOX_SIZE = 50;


}
