#include "DetermineEarlyRegionsMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "System/Util/Collision/CollisionWorldBruteForce.h"

#include <cassert>
#include <cmath>

namespace ProceduralExplorationGameCore{

    DetermineEarlyRegionsMapGenStep::DetermineEarlyRegionsMapGenStep() : MapGenStep("Determine Early Regions"){

    }

    DetermineEarlyRegionsMapGenStep::~DetermineEarlyRegionsMapGenStep(){

    }

    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    WorldPoint _determineRegionPoint(const std::vector<FloodFillEntry*>& landData, const std::vector<LandId>& landWeighted, LandId biggestLand, const ExplorationMapData* mapData, AV::CollisionWorldObject* collisionWorld, int size){
        //Attempt a few times, otherwise fail.
        for(int i = 0; i < 30; i++){
            //Determine a single point and retry if it's too close to the others.
            //LandId retLandmass = findRandomLandmassForSize(landData, landWeighted, 20);
            //LandId retLandmass = landData.empty() ? INVALID_LAND_ID : 0;
            //if(retLandmass == INVALID_LAND_ID) continue;

            const std::vector<WorldPoint>& coordData = landData[biggestLand]->coords;
            size_t randIndex = mapGenRandomIndex<WorldPoint>(coordData);
            WorldPoint randPoint = coordData[randIndex];
            //Determine if that point collides with anything

            WorldCoord xx, yy;
            READ_WORLD_POINT(randPoint, xx, yy);
            bool collides = collisionWorld->checkCollisionPoint(xx, yy, size);
            if(collides){
                continue;
            }

            collisionWorld->addCollisionPoint(xx, yy, size);

            return randPoint;
        }

        return INVALID_WORLD_POINT;
    }

    void _determinePoints(const ExplorationMapData* mapData, std::vector<RegionSeedData>& points, std::vector<RegionData>& regionData, AV::CollisionWorldObject* collisionWorld){
        const AV::uint32 width = mapData->uint32("width");
        const AV::uint32 height = mapData->uint32("height");

        int padWidth = 30;
        int padHeight = 30;
        for(int y = 0; y < height; y += padWidth){
            for(int x = 0; x < width; x += padHeight){
                const AV::uint8* land = LAND_GROUP_PTR_FOR_COORD_CONST(mapData, WRAP_WORLD_POINT(x, y));
                if(*land == INVALID_LAND_ID) continue;

                if(mapGenRandomIntMinMax(0, 2) == 0){
                    continue;
                }

                WorldCoord xx = x + mapGenRandomIntMinMax(padWidth * 0.75, padWidth);
                WorldCoord yy = y + mapGenRandomIntMinMax(padHeight * 0.75, padHeight);

                bool collided = collisionWorld->checkCollisionPoint(xx, yy, 2);
                if(collided){
                    continue;
                }

                points.push_back({WRAP_WORLD_POINT(xx, yy), 20});
                regionData.push_back({
                    static_cast<RegionId>(regionData.size()),
                    0,
                    static_cast<WorldCoord>(xx),
                    static_cast<WorldCoord>(yy),
                    RegionType::NONE,
                    0
                });
            }
        }
    }

    void DetermineEarlyRegionsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        int totalRegions = input->uint32("numRegions");
        //For the special regions.
        totalRegions += 20;

        AV::CollisionWorldBruteForce* bruteForceCollision = new AV::CollisionWorldBruteForce(0);

        std::vector<RegionSeedData> points;
        //points.resize(totalRegions + 3, {0, 10});
        for(RegionId i = 0; i < 3; i++){
                //points[i].size = 100;
                WorldPoint blobSeed = workspace->blobSeeds[i];
                WorldCoord xp, yp;
                READ_WORLD_POINT(blobSeed, xp, yp);
                //points[i].p = blobSeed;
                points.push_back({blobSeed, 100});
                bruteForceCollision->addCollisionPoint(xp, yp, 80);

                mapData->regionData.push_back({
                    i,
                    0,
                    xp,
                    yp,
                    RegionType::NONE,
                    1
                });
        }

        _determinePoints(mapData, points, mapData->regionData, bruteForceCollision);

        /*
        LandId biggestLand = findBiggestFloodEntry(workspace->landData);
        if(biggestLand != INVALID_LAND_ID){
            for(RegionId i = 2; i < totalRegions + 3; i++){
                AV::uint8 pointSize = 10;
                WorldPoint p = _determineRegionPoint(workspace->landData, workspace->landWeighted, biggestLand, mapData, bruteForceCollision, pointSize);
                if(p == INVALID_WORLD_POINT) continue;

                WorldCoord xx, yy;
                READ_WORLD_POINT(p, xx, yy);
                //points[i].p = p;
                points.push_back({p, pointSize});
                mapData->regionData.push_back({
                    i,
                    0,
                    xx,
                    yy,
                    RegionType::NONE,
                    0
                });
            }
        }
        else{
            //Incase there were no landmasses, push a single point.
            //points.push_back({0, pointSize});
            mapData->regionData.push_back({
                0,
                0,
                0,
                0,
                RegionType::NONE,
                0
            });
        }
         */

        delete bruteForceCollision;

        //TODO separate this into jobs for threads.

        int div = 4;
        int divHeight = input->uint32("height") / div;
        for(int i = 0; i < 4; i++){
            DetermineEarlyRegionsMapGenJob job;
            job.processJob(mapData, points, mapData->regionData, 0, i * divHeight, input->uint32("width"), i * divHeight + divHeight);
        }

        //Go through the produced list and remove any regions with no coordinates
        auto it = mapData->regionData.begin();
        while(it != mapData->regionData.end()){
            if(it->total == 0){
                assert(it->coords.size() == 0);
                it = mapData->regionData.erase(it);
            }else{
                it++;
            }
        }
        for(RegionData r : mapData->regionData){
            assert(r.coords.size() != 0);
        }

        //Write those values to the buffer
        for(RegionId r = 0; r < mapData->regionData.size(); r++){
            RegionData& d = mapData->regionData[r];
            d.id = r;
        //for(const RegionData& r : mapData->regionData){
            for(WorldPoint p : d.coords){
                RegionId* regionPtr = REGION_PTR_FOR_COORD(mapData, p);
                *regionPtr = r;
            }
        }
    }

    DetermineEarlyRegionsMapGenJob::DetermineEarlyRegionsMapGenJob(){

    }

    DetermineEarlyRegionsMapGenJob::~DetermineEarlyRegionsMapGenJob(){

    }

    void DetermineEarlyRegionsMapGenJob::processJob(ExplorationMapData* mapData, const std::vector<RegionSeedData>& points, std::vector<RegionData>& regionData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        const AV::uint32 seaLevel = mapData->uint32("seaLevel");

        AV::uint8* regionPtr = REGION_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(xa, ya));
        for(int y = ya; y < yb; y++){
            for(int x = xa; x < xb; x++){
                //Skip water for region assignment.
                /*
                WorldPoint currentPoint = WRAP_WORLD_POINT(x, y);
                WaterId water = *WATER_GROUP_PTR_FOR_COORD_CONST(mapData, currentPoint);
                if(water != INVALID_WATER_ID){
                    //regionPtr+=4;
                    continue;
                }
                 */

                WorldPoint currentPoint = WRAP_WORLD_POINT(x, y);
                AV::uint8 altitude = *(VOX_PTR_FOR_COORD_CONST(mapData, currentPoint));
                if(altitude < seaLevel) continue;

                float closest = 10000.0;
                int closestIdx = -1;

                for(int i = 0; i < points.size(); i++){
                    WorldPoint p = points[i].p;

                    WorldCoord xTarget, yTarget;
                    READ_WORLD_POINT(p, xTarget, yTarget);

                    float length = distance(xTarget, yTarget, x, y);
                    if(length < closest){
                        closest = length;
                        closestIdx = i;
                    }
                }
                if(closestIdx != -1){
                    //TODO For threading this needs to be pushed to separate lists and merged later.
                    regionData[closestIdx].coords.push_back(currentPoint);
                    regionData[closestIdx].total++;
                }else{
                    closestIdx = 0;
                }

                //(*regionPtr) = (closestIdx & 0xFF);
                //regionPtr+=4;
            }
        }
    }

}
