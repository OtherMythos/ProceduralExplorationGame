#include "MergeAltitudeMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    MergeAltitudeMapGenStep::MergeAltitudeMapGenStep() : MapGenStep("Merge Altitude"){

    }

    MergeAltitudeMapGenStep::~MergeAltitudeMapGenStep(){

    }

    MergeAltitudeMapGenJob::MergeAltitudeMapGenJob(){

    }

    MergeAltitudeMapGenJob::~MergeAltitudeMapGenJob(){

    }

    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    inline float getHeightForPoint(float input, float x, float y, int xx, int yy, int width, const std::vector<float>& additionVals){


        float val = 0;
#define INCLUDE_PERLIN
#ifdef INCLUDE_PERLIN
        static const float ORIGIN = 0.5;
        float centreOffset = (distance(ORIGIN, ORIGIN, x, y) + 0.1);
        float curvedOffset = 1 - pow(2, -10 * centreOffset*1.8);

        val = (1.0f-centreOffset*1.2) * input;
        val *= 1.3;
#endif

        val += additionVals[xx + yy * width] * 1.2;

        //Determine the line between the two points and calculate the distance from that

        if(val > 1.0f) val = 1.0f;
        return val;
    }

    void MergeAltitudeMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        int div = 4;
        int divHeight = height / div;
        for(int i = 0; i < 4; i++){
            MergeAltitudeMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, width, i * divHeight + divHeight, workspace->additionLayer);
        }
    }


    void MergeAltitudeMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb, const std::vector<float>& additionVals){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        float* voxPtr = static_cast<float*>(mapData->voidPtr("voxelBuffer"));
        for(AV::uint32 y = ya; y < yb; y++){
            float yVal = (float)y / (float)height;
            for(AV::uint32 x = xa; x < xb; x++){
                float xVal = (float)x / (float)width;
                float* target = (voxPtr + (x+y*width));

                float heightForPoint = getHeightForPoint(*target, xVal, yVal, x, y, width, additionVals);
                *target = heightForPoint;
            }
        }
    }
}
