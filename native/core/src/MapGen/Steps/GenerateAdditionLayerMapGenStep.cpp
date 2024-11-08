#include "GenerateAdditionLayerMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{

    //static const float BLOB_SIZE = 0.18;
    static const float BLOB_SIZE = 200;
    static const float HALF_BLOB_SIZE = BLOB_SIZE/2;
    static const float LINE_BOX_SIZE = 50;

    static float pointX[] = {0.2, 0.3, 0.8};
    static float pointY[] = {0.2, 0.8, 0.8};

    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
    }

    void determinePositionForBlob_(const ExplorationMapData* mapData, int idx){
        float xx, yy;
        xx = yy = 0.0f;
        for(int i = 0; i < 50; i++){
            xx = float(mapGenRandomIntMinMax(HALF_BLOB_SIZE, mapData->width - HALF_BLOB_SIZE)) / mapData->width;
            yy = float(mapGenRandomIntMinMax(HALF_BLOB_SIZE, mapData->height - HALF_BLOB_SIZE)) / mapData->height;
            if(idx == 0){
                break;
            }

            bool collision = false;
            for(int c = 0; c <= idx - 1; c++){
                //Check the current random pos with the other points.
                float d = distance(xx, yy, pointX[c], pointY[c]);
                if(d < (float(BLOB_SIZE) / mapData->width)){
                    collision = true;
                }
            }
            if(!collision){
                break;
            }
        }

        pointX[idx] = xx;
        pointY[idx] = yy;
    }

    void calculateBresenhamLine(int startX, int startY, int endX, int endY, std::set<WorldPoint>& outPoints){
        outPoints.clear();

        int deltaX = abs(endX - startX);
        int deltaY = abs(endY - startY);

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

            assert(pointX >= 0 && pointY >= 0 && pointX < 600 && pointY < 600);

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

    void calculateBlobs_(std::vector<float>& additionalVals, ExplorationMapData* mapData){
        for(int i = 0; i < 3; i++){
            int px = pointX[i] * mapData->width;
            int py = pointY[i] * mapData->height;

            for(int y = 0; y < BLOB_SIZE; y++){
                for(int x = 0; x < BLOB_SIZE; x++){
                    int xx = (x + px - BLOB_SIZE/2);
                    int yy = (y + py - BLOB_SIZE/2);

                    if(xx < 0 || yy < 0 || xx >= mapData->width || yy >= mapData->height) continue;

                    size_t valIdx = xx + yy * mapData->width;
                    float regionOffset = distance(xx, yy, px, py);
                    float val = float(BLOB_SIZE/2 - regionOffset)/mapData->width;
                    val *= 2;
                    if(val > additionalVals[valIdx]){
                        additionalVals[valIdx] = val;
                    }
                }
            }
        }
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
            for(int yy = -LINE_BOX_SIZE; yy < LINE_BOX_SIZE; yy++){
                for(int xx = -LINE_BOX_SIZE; xx < LINE_BOX_SIZE; xx++){
                    drawPoints.insert(WRAP_WORLD_POINT(x + xx, y + yy));
                }
            }
        }

        for(WorldPoint p : drawPoints){
            WorldCoord xx, yy;
            READ_WORLD_POINT(p, xx, yy);
            float distance = ((LINE_BOX_SIZE)/mapData->width) - pointToLineDistance(float(xx)/mapData->width, float(yy)/mapData->height, pointX[idx+0], pointY[idx+0], pointX[idx+1], pointY[idx+1]);
            //distance = tan(distance) * 2;
            size_t valIdx = xx + yy * mapData->width;
            if(distance > additionVals[valIdx]){
                additionVals[valIdx] = distance;
            }
        }
    }

    GenerateAdditionLayerMapGenStep::GenerateAdditionLayerMapGenStep(){

    }

    GenerateAdditionLayerMapGenStep::~GenerateAdditionLayerMapGenStep(){

    }

    void GenerateAdditionLayerMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){

        for(int i = 0; i < 3; i++){
            determinePositionForBlob_(mapData, i);
        }


        std::vector<float> additionVals;
        additionVals.resize(mapData->width * mapData->height);


        for(int i = 0; i < 3-1; i++){
            calculateLines_(i, additionVals, mapData);
        }
        //for(int i = 0; i < 3; i++){
            calculateBlobs_(additionVals, mapData);
        //}

        workspace->additionLayer = std::move(additionVals);
    }
}
