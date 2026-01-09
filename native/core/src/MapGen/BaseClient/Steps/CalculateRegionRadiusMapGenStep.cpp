#include "CalculateRegionRadiusMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include <cmath>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    CalculateRegionRadiusMapGenStep::CalculateRegionRadiusMapGenStep() : MapGenStep("Calculate Region Radius"){

    }

    CalculateRegionRadiusMapGenStep::~CalculateRegionRadiusMapGenStep(){

    }

    bool CalculateRegionRadiusMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        CalculateRegionRadiusMapGenJob job;
        job.processJob(mapData, workspace);

        return true;
    }

    CalculateRegionRadiusMapGenJob::CalculateRegionRadiusMapGenJob(){

    }

    CalculateRegionRadiusMapGenJob::~CalculateRegionRadiusMapGenJob(){

    }

    void CalculateRegionRadiusMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = *mapData->ptr<std::vector<RegionData>>("regionData");

        for(RegionData& region : regionData){
            if(region.coords.empty()){
                region.radius = 0.0f;
                continue;
            }

            //Get centre point
            WorldCoord centreX, centreY;
            READ_WORLD_POINT(region.centrePoint, centreX, centreY);

            //Calculate squared distances from centre to all points
            std::vector<float> distancesSquared;
            distancesSquared.reserve(region.coords.size());

            for(WorldPoint wp : region.coords){
                WorldCoord x, y;
                READ_WORLD_POINT(wp, x, y);

                float dx = static_cast<float>(x) - static_cast<float>(centreX);
                float dy = static_cast<float>(y) - static_cast<float>(centreY);
                float distanceSquared = dx * dx + dy * dy;

                distancesSquared.push_back(distanceSquared);
            }

            //Sort squared distances to find percentiles
            std::sort(distancesSquared.begin(), distancesSquared.end());

            //Use the 90th percentile as the squared radius to avoid outliers.
            //This ignores the 10% of points that are furthest from the centre.
            size_t percentile90Index = static_cast<size_t>(distancesSquared.size() * 0.9f);
            if(percentile90Index >= distancesSquared.size()){
                percentile90Index = distancesSquared.size() - 1;
            }

            region.radius = std::sqrt(distancesSquared[percentile90Index]);
        }
    }
}
