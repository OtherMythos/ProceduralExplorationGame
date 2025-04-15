#include "GenerateMetaMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cmath>

namespace ProceduralExplorationGameCore{

    GenerateMetaMapGenStep::GenerateMetaMapGenStep() : MapGenStep("Generate Meta"){

    }

    GenerateMetaMapGenStep::~GenerateMetaMapGenStep(){

    }

    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    WorldPoint determinePositionForBlob_(const ExplorationMapData* mapData, const std::vector<WorldPoint>& seeds, int idx){
        WorldCoord xx, yy;
        xx = yy = 0;
        for(int i = 0; i < 50; i++){
            xx = mapGenRandomIntMinMax(HALF_BLOB_SIZE, mapData->width - HALF_BLOB_SIZE);
            yy = mapGenRandomIntMinMax(HALF_BLOB_SIZE, mapData->height - HALF_BLOB_SIZE);
            if(idx == 0){
                break;
            }

            bool collision = false;
            for(int c = 0; c <= idx - 1; c++){
                //Check the current random pos with the other points.
                WorldPoint testPoint = seeds[c];
                WorldCoord xp, yp;
                READ_WORLD_POINT(testPoint, xp, yp);
                float d = distance(xx, yy, xp, yp);
                if(d < BLOB_SIZE){
                    collision = true;
                }
            }
            if(!collision){
                break;
            }
        }

        return WRAP_WORLD_POINT(xx, yy);
    }

    void GenerateMetaMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        mapData->width = input->width;
        mapData->height = input->height;
        mapData->seaLevel = input->seaLevel;

        mapData->moistureSeed = input->moistureSeed;
        mapData->seed = input->seed;
        mapData->variationSeed = input->variationSeed;

        RandomWrapper::singleton.seed(mapData->variationSeed);

        for(int i = 0; i < 3; i++){
            WorldPoint p = determinePositionForBlob_(mapData, workspace->blobSeeds, i);
            workspace->blobSeeds.push_back(p);
        }
    }

}
