#include "IsolateRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "Util/FloodFill.h"

#include <cassert>
#include <cmath>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    IsolateRegionsMapGenStep::IsolateRegionsMapGenStep() : MapGenStep("Isolate Regions"){

    }

    IsolateRegionsMapGenStep::~IsolateRegionsMapGenStep(){

    }

    typedef AV::uint32 WrappedAltitudeRegion;

    RegionId checkRegion = INVALID_REGION_ID;
    AV::uint32 checkSeaLevel = 0;
    inline bool comparisonValues(ExplorationMapData* mapData, WrappedAltitudeRegion val){
        AV::uint8 altitude = (val >> 16) & 0xFFFF;
        RegionId region = val & 0xFFFF;
        return altitude >= mapData->seaLevel && region == checkRegion;
    }
    inline WrappedAltitudeRegion readValues(ExplorationMapData* mapData, AV::uint32 x, AV::uint32 y){
        AV::uint8 altitude = *(VOX_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y)));
        RegionId region = *(REGION_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(x, y)));
        return static_cast<AV::uint32>(altitude) << 16 | region;
    }
    void isolateRegion(ExplorationMapData* mapData, RegionData& region, std::vector<RegionId>& vals){
        //checkRegion = region.id;

        //TODO don't place inline.
        //std::vector<RegionId> valsOther;
        //valsOther.resize(mapData->width * mapData->height, INVALID_REGION_ID);

        std::vector<FloodFillEntry*> regionResult;
        assert(!region.coords.empty());
        WorldPoint startingCoord = region.coords[0];
        WorldCoord xp, yp;
        READ_WORLD_POINT(startingCoord, xp, yp);
        //void inline _floodFillForPos(T comparisonFunction, C readFunction, int x, int y, ExplorationMapData* mapData, AV::uint32 currentIdx, std::vector<RegionId>& vals, std::vector<FloodFillEntry*>& outData, bool writeToBlob=true){
        AV::uint32 currentIdx = 0;
        _floodFillForPos
            <bool(ExplorationMapData*, WrappedAltitudeRegion),WrappedAltitudeRegion(ExplorationMapData*, AV::uint32, AV::uint32), AV::uint32, 2>
            (comparisonValues, readValues, xp, yp, mapData, currentIdx, vals, regionResult, mapData->uint32("width"), mapData->uint32("height"), false);
        //mapData->waterData = std::move(waterResult);

        assert(regionResult.size() == 1);

        region.edges = std::move(regionResult[0]->edges);

        //Determine if the region is concave.
        if(regionResult[0]->coords.size() == region.coords.size()){
            return;
        }

        //Remove the flood fill coordinates from the first list and split the other value off into a new region
        const std::vector<WorldPoint>& trimPoints = regionResult[0]->coords;
        assert(region.coords.size() > trimPoints.size());
        for(WorldPoint c : trimPoints){
            auto it = std::find(region.coords.begin(), region.coords.end(), c);
            if(it == region.coords.end()){
                continue;
            }
            region.coords.erase(it);
        }
        std::vector<WorldPoint> newCoords = std::move(region.coords);
        region.coords = std::move(regionResult[0]->coords);
        region.total = region.coords.size();

        assert(newCoords.size() > 0);
        WorldCoord xnp, ynp;
        READ_WORLD_POINT(newCoords[0], xnp, ynp);
        mapData->regionData.push_back({
            static_cast<RegionId>(mapData->regionData.size()),
            0,
            xnp,
            ynp,
            RegionType::NONE,
            0
        });

        RegionData& newRegion = mapData->regionData[mapData->regionData.size()-1];
        newRegion.coords = std::move(newCoords);
        newRegion.total = newRegion.coords.size();

        isolateRegion(mapData, newRegion, vals);
    }

    void IsolateRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        //For each region
        //Start on the first coordinate, from there flood fill outwards until completion.
        //If the flood fill coords match the length of the coords length then the region is concave and return.
        //If not, make a copy of the coords list and take away all the coordinates which were present in the flood fill.
        //Update the old region coords to match the new ones and write to the buffer
        //Repeat the process until the coords list is empty

        //Save the sea level to prevent the lookup happening regularly.
        checkSeaLevel = mapData->uint32("seaLevel");

        std::vector<RegionId> vals;
        vals.resize(mapData->uint32("width") * mapData->uint32("height"), INVALID_REGION_ID);
        int len = mapData->regionData.size();
        for(int i = 0; i < len; i++){
        //auto it = mapData->regionData.begin();
        //while(it != mapData->regionData.end()){
            RegionData& r = mapData->regionData[i];
            checkRegion = r.id;
            isolateRegion(mapData, r, vals);
            //it++;
        }

    }

    IsolateRegionsMapGenJob::IsolateRegionsMapGenJob(){

    }

    IsolateRegionsMapGenJob::~IsolateRegionsMapGenJob(){

    }

    void IsolateRegionsMapGenJob::processJob(ExplorationMapData* mapData, const std::vector<WorldPoint>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
    }

}
