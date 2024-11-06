#include "ReduceNoiseMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    ReduceNoiseMapGenStep::ReduceNoiseMapGenStep(){

    }

    ReduceNoiseMapGenStep::~ReduceNoiseMapGenStep(){

    }

    void ReduceNoiseMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        int div = 4;
        int divHeight = input->height / div;
        for(int i = 0; i < 4; i++){
            ReduceNoiseMapGenJob job;
            job.processJob(mapData, 0, i * divHeight, input->width, i * divHeight + divHeight);
        }
    }



    ReduceNoiseMapGenJob::ReduceNoiseMapGenJob(){

    }

    ReduceNoiseMapGenJob::~ReduceNoiseMapGenJob(){

    }

    static float pointX[] = {0.2, 0.3, 0.8};
    static float pointY[] = {0.2, 0.8, 0.8};

    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    void calculateBresenhamLine(int startX, int startY, int endX, int endY, std::set<WorldPoint>& outPoints){
        outPoints.clear();

        int deltaX = endX - startX;
        int deltaY = endY - startY;

        int pointX = startX;
        int pointY = startY;

        int horizontalStep = (startX < endX) ? 1 : -1;
        int verticalStep = (startY < endY) ? 1 : -1;

        int difference = deltaX - deltaY;
        while(true){
            int doubleDifference = 2 * difference;
            if(doubleDifference > -deltaY){
                difference -= deltaY;
                pointX += horizontalStep;
            }
            if(doubleDifference < deltaX){
                difference += deltaX;
                pointY += verticalStep;
            }

            if(pointX == endX && pointY == endY) break;

            outPoints.insert(WRAP_WORLD_POINT(pointX, pointY));
        }
    }

    double pointToLineDistance(double x0, double y0, double x1, double y1, double x2, double y2) {
        // Calculate differences
        double dx = x2 - x1;
        double dy = y2 - y1;

        // Calculate the numerator and denominator of the distance formula
        double numerator = std::abs(dy * x0 - dx * y0 + x2 * y1 - y2 * x1);
        double denominator = std::sqrt(dx * dx + dy * dy);

        // If denominator is zero, the line segment is just a point; return 0 as a fallback
        return (denominator != 0) ? (numerator / denominator) : 0.0;
    }
    static const int BOX_SIZE = 40;

    inline float getHeightForPoint(float input, float x, float y, int xx, int yy, const std::vector<float>& additionVals){


        float val = 0;
#define INCLUDE_PERLIN
#ifdef INCLUDE_PERLIN
        static const float ORIGIN = 0.5;
        float centreOffset = (distance(ORIGIN, ORIGIN, x, y) + 0.1);
        float curvedOffset = 1 - pow(2, -10 * centreOffset*1.8);

        val = (1.0f-centreOffset*1.2) * input;
        val *= 1.3;
#endif


        /*
        //float val = 0.0;
        for(int i = 0; i < 3; i++){
            static const float BLOB_SIZE = 0.18;
            //Determine how close it is to a main region.
            float regionOffset = (distance(pointX[i], pointY[i], x, y));
            if(regionOffset <= BLOB_SIZE){
                float modAmount = (BLOB_SIZE - regionOffset);

                //val += modAmount * 2 + (input*0.2);
                val += modAmount * 2;
            }
        }

        if(points.find(WRAP_WORLD_POINT(xx, yy)) != points.end()){
            //If the point exists in this list.
            //TODO plug in the actual world width
            float distance = ((BOX_SIZE*2)/600.0f) - pointToLineDistance(x, y, pointX[0], pointY[0], pointX[1], pointY[1]);
            val += distance;
            //val += 1.0 * 2 + (1.0*0.2);

        }
         */
        val += additionVals[xx + yy * 600] * 1.2;

        //Determine the line between the two points and calculate the distance from that

        if(val > 1.0f) val = 1.0f;
        return val;
    }

    void calculateLines_(int idx, std::vector<float>& additionVals, ExplorationMapData* mapData){
        int startX = static_cast<int>(pointX[idx+0] * mapData->width);
        int startY = static_cast<int>(pointY[idx+0] * mapData->height);
        int endX = static_cast<int>(pointX[idx+1] * mapData->width);
        int endY = static_cast<int>(pointY[idx+1] * mapData->height);

        std::set<WorldPoint> linePoints;
        calculateBresenhamLine(startX, startY, endX, endY, linePoints);

        //Calculate the thicker line
        std::set<WorldPoint> drawPoints;
        for(WorldPoint p : linePoints){
            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);
            for(int yy = -BOX_SIZE; yy < BOX_SIZE; yy++){
                for(int xx = -BOX_SIZE; xx < BOX_SIZE; xx++){
                    drawPoints.insert(WRAP_WORLD_POINT(x + xx, y + yy));
                }
            }
        }

        for(WorldPoint p : drawPoints){
            WorldCoord xx, yy;
            READ_WORLD_POINT(p, xx, yy);
            float distance = ((BOX_SIZE)/mapData->width) - pointToLineDistance(float(xx)/mapData->width, float(yy)/mapData->height, pointX[idx+0], pointY[idx+0], pointX[idx+1], pointY[idx+1]);
            distance = tan(distance) * 2;
            size_t valIdx = xx + yy * mapData->width;
            if(distance > additionVals[valIdx]){
                additionVals[valIdx] = distance;
            }
        }
    }

    void calculateBlobs_(int idx, std::vector<float>& additionalVals, ExplorationMapData* mapData){
        static const float BLOB_SIZE = 0.18;

        for(int i = 0; i < 3; i++){
            for(AV::uint32 y = 0; y < mapData->height; y++){
                for(AV::uint32 x = 0; x < mapData->width; x++){

                    //Determine how close it is to a main region.
                    float regionOffset = (distance(pointX[i], pointY[i], float(x)/mapData->width, float(y)/mapData->height));
                    if(regionOffset <= BLOB_SIZE){
                        float modAmount = (BLOB_SIZE - regionOffset);

                        //val += modAmount * 2 + (input*0.2);
                        float writeVal = modAmount * 2;
                        size_t valIdx = x + y * mapData->width;
                        if(writeVal > additionalVals[valIdx]){
                            additionalVals[valIdx] = writeVal;
                        }
                    }

                }
            }
        }
    }

    void ReduceNoiseMapGenJob::processJob(ExplorationMapData* mapData, WorldCoord xa, WorldCoord ya, WorldCoord xb, WorldCoord yb){
        std::vector<float> additionVals;
        additionVals.resize(mapData->width * mapData->height);

        for(int i = 0; i < 3-1; i++){
            calculateLines_(i, additionVals, mapData);
        }
        for(int i = 0; i < 3; i++){
            calculateBlobs_(i, additionVals, mapData);
        }



        {
            float* voxPtr = static_cast<float*>(mapData->voxelBuffer);
            for(AV::uint32 y = ya; y < yb; y++){
                float yVal = (float)y / (float)mapData->height;
                for(AV::uint32 x = xa; x < xb; x++){
                    float xVal = (float)x / (float)mapData->width;
                    float* target = (voxPtr + (x+y*mapData->width));

                    float heightForPoint = getHeightForPoint(*target, xVal, yVal, x, y, additionVals);
                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(heightForPoint * (float)0xFF);
                }
            }
        }

        /*
        if(false){
            //Write the other values
            float* voxPtr = static_cast<float*>(mapData->voxelBuffer);
            for(WorldPoint i : drawPoints){
                WorldCoord x, y;
                READ_WORLD_POINT(i, x, y);
                *(reinterpret_cast<AV::uint32*>(voxPtr) + (x + y * mapData->width)) = 0xFF /4 ;
            }
        }
         */

        {
            float* voxPtr = static_cast<float*>(mapData->secondaryVoxelBuffer);
            for(AV::uint32 y = ya; y < yb; y++){
                for(AV::uint32 x = xa; x < xb; x++){
                    float* target = (voxPtr + (x+y*mapData->width));
                    float val = (*target * (float)0xFF);
                    assert(val <= (float)0xFF);
                    *(reinterpret_cast<AV::uint32*>(target)) = static_cast<AV::uint32>(val);
                }
            }
        }

    }
}
