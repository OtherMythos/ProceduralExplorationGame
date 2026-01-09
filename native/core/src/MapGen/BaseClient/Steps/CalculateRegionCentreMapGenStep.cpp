#include "CalculateRegionCentreMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"
#include <cmath>

namespace ProceduralExplorationGameCore{

    CalculateRegionCentreMapGenStep::CalculateRegionCentreMapGenStep() : MapGenStep("Calculate Region Centre"){

    }

    CalculateRegionCentreMapGenStep::~CalculateRegionCentreMapGenStep(){

    }

    bool CalculateRegionCentreMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        CalculateRegionCentreMapGenJob job;
        job.processJob(mapData, workspace);

        return true;
    }

    CalculateRegionCentreMapGenJob::CalculateRegionCentreMapGenJob(){

    }

    CalculateRegionCentreMapGenJob::~CalculateRegionCentreMapGenJob(){

    }

    void CalculateRegionCentreMapGenJob::processJob(ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = *mapData->ptr<std::vector<RegionData>>("regionData");

        for(RegionData& region : regionData){
            if(region.coords.empty()){
                region.centrePoint = 0;
                continue;
            }

            //Calculate the geometric median using a robust algorithm that handles outliers.
            //We use the Weiszfeld algorithm: an iterative algorithm that converges to the
            //geometric median (the point minimising sum of distances to all points).

            const size_t MAX_ITERATIONS = 20;
            const float CONVERGENCE_THRESHOLD = 0.1f;

            //Initial estimate: use the median point coordinates
            float centreX = 0.0f;
            float centreY = 0.0f;

            std::vector<float> xCoords, yCoords;
            for(WorldPoint wp : region.coords){
                WorldCoord x, y;
                READ_WORLD_POINT(wp, x, y);
                xCoords.push_back(static_cast<float>(x));
                yCoords.push_back(static_cast<float>(y));
            }

            //Sort to find median
            std::sort(xCoords.begin(), xCoords.end());
            std::sort(yCoords.begin(), yCoords.end());

            //Start with median as initial guess
            centreX = xCoords[xCoords.size() / 2];
            centreY = yCoords[yCoords.size() / 2];

            //Weiszfeld iteration to refine the centre
            for(size_t iter = 0; iter < MAX_ITERATIONS; iter++){
                float sumX = 0.0f;
                float sumY = 0.0f;
                float sumWeights = 0.0f;

                for(WorldPoint wp : region.coords){
                    WorldCoord x, y;
                    READ_WORLD_POINT(wp, x, y);
                    float px = static_cast<float>(x);
                    float py = static_cast<float>(y);

                    float dx = px - centreX;
                    float dy = py - centreY;
                    float distance = std::sqrt(dx * dx + dy * dy);

                    if(distance < 0.001f) continue; //Skip nearly duplicate points

                    float weight = 1.0f / distance;
                    sumX += px * weight;
                    sumY += py * weight;
                    sumWeights += weight;
                }

                if(sumWeights < 0.001f) break; //Degenerate case

                float newCentreX = sumX / sumWeights;
                float newCentreY = sumY / sumWeights;

                float changeMagnitude = std::sqrt(
                    (newCentreX - centreX) * (newCentreX - centreX) +
                    (newCentreY - centreY) * (newCentreY - centreY)
                );

                centreX = newCentreX;
                centreY = newCentreY;

                if(changeMagnitude < CONVERGENCE_THRESHOLD){
                    break;
                }
            }

            //Round to nearest integer and convert to WorldPoint
            WorldCoord finalX = static_cast<WorldCoord>(std::round(centreX));
            WorldCoord finalY = static_cast<WorldCoord>(std::round(centreY));

            region.centrePoint = WRAP_WORLD_POINT(finalX, finalY);
        }
    }
}
