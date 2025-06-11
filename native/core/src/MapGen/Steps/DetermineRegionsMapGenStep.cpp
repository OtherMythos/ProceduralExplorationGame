#include "DetermineRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>

namespace ProceduralExplorationGameCore{

    DetermineRegionsMapGenStep::DetermineRegionsMapGenStep() : MapGenStep("Determine Regions"){

    }

    DetermineRegionsMapGenStep::~DetermineRegionsMapGenStep(){

    }

    WorldPoint _determineRegionPoint(const std::vector<FloodFillEntry*>& landData, const std::vector<LandId>& landWeighted, const ExplorationMapData* mapData){
        //Attempt a few times, otherwise fail.
        for(int i = 0; i < 10; i++){
            //Determine a single point and retry if it's too close to the others.
            LandId retLandmass = findRandomLandmassForSize(landData, landWeighted, 20);
            if(retLandmass == INVALID_LAND_ID) continue;
            const std::vector<WorldPoint>& coordData = landData[retLandmass]->coords;
            //local randIndex = _random.randIndex(coordData);
            size_t randIndex = mapGenRandomIndex<WorldPoint>(coordData);
            WorldPoint randPoint = coordData[randIndex];

            return randPoint;
        }

        return INVALID_WORLD_POINT;
    }

    void DetermineRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = input->uint32("width");
        const AV::uint32 height = input->uint32("height");

        std::vector<WorldPoint> points;
        points.reserve(input->uint32("numRegions"));
        for(RegionId i = 0; i < input->uint32("numRegions"); i++){
            WorldPoint p = _determineRegionPoint(mapData->landData, workspace->landWeighted, mapData);
            if(p == INVALID_WORLD_POINT) continue;

            WorldCoord xx, yy;
            READ_WORLD_POINT(p, xx, yy);
            points.push_back(p);
            mapData->regionData.push_back({
                i,
                0,
                static_cast<AV::uint16>(xx),
                static_cast<AV::uint16>(yy),
                RegionType::NONE,
            });
        }

        //TODO separate this into jobs for threads.

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            DetermineRegionsMapGenJob job;
            job.processJob(mapData, points, mapData->regionData, 0, i * divHeight, width, i * divHeight + divHeight);
        }
    }

    DetermineRegionsMapGenJob::DetermineRegionsMapGenJob(){

    }

    DetermineRegionsMapGenJob::~DetermineRegionsMapGenJob(){

    }

    void DetermineRegionsMapGenJob::processJob(ExplorationMapData* mapData, const std::vector<WorldPoint>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        AV::uint8* regionPtr = REGION_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(xa, ya));
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                float closest = 10000.0;
                int closestIdx = -1;

                for(int i = 0; i < points.size(); i++){
                    WorldPoint p = points[i];

                    WorldCoord xTarget, yTarget;
                    READ_WORLD_POINT(p, xTarget, yTarget);

                    float length = sqrt(pow(static_cast<int>(xTarget) - x, 2) + pow(static_cast<int>(yTarget) - y, 2));
                    if(length < closest){
                        closest = length;
                        closestIdx = i;
                    }
                }
                if(closestIdx != -1){
                    //TODO For threading this needs to be pushed to separate lists and merged later.
                    regionData[closestIdx].coords.push_back(WRAP_WORLD_POINT(x, y));
                }else{
                    closestIdx = 0;
                }

                (*regionPtr) = (closestIdx & 0xFF);
                regionPtr+=4;
            }
        }
    }

}
