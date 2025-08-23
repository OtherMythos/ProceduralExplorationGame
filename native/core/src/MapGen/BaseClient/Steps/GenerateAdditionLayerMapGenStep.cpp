#include "GenerateAdditionLayerMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <cmath>
#include <set>

namespace ProceduralExplorationGameCore{


    inline float distance(float x1, float y1, float x2, float y2){
        return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
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

            //assert(pointX >= 0 && pointY >= 0 && pointX < 600 && pointY < 600);

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

    void calculateBlobs_(std::vector<float>& additionalVals, ExplorationMapData* mapData, const std::vector<WorldPoint>& blobPositions){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        for(int i = 0; i < 3; i++){
            WorldCoord px, py;
            READ_WORLD_POINT(blobPositions[i], px, py);

            for(int y = 0; y < BLOB_SIZE; y++){
                for(int x = 0; x < BLOB_SIZE; x++){
                    int xx = (x + px - BLOB_SIZE/2);
                    int yy = (y + py - BLOB_SIZE/2);

                    if(xx < 0 || yy < 0 || xx >= width || yy >= height) continue;

                    size_t valIdx = xx + yy * width;
                    float regionOffset = distance(xx, yy, px, py);
                    float val = float(BLOB_SIZE/2 - regionOffset)/width;
                    val *= 2;
                    if(val > additionalVals[valIdx]){
                        additionalVals[valIdx] = val;
                    }
                }
            }
        }
    }

    void calculateLines_(int idx, std::vector<float>& additionVals, ExplorationMapData* mapData, const std::vector<WorldPoint>& blobPositions){
        const AV::uint32 width = mapData->width;

        WorldCoord x1, y1, x2, y2;
        READ_WORLD_POINT(blobPositions[idx], x1, y1);
        READ_WORLD_POINT(blobPositions[idx+1], x2, y2);
        int startX = x1;
        int startY = y1;
        int endX = x2;
        int endY = y2;

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

        const float maxDistance = sqrt(pow(LINE_BOX_SIZE, 2) * 2) * 1.05;
        for(WorldPoint p : drawPoints){
            WorldCoord xx, yy;
            READ_WORLD_POINT(p, xx, yy);
            double lineDistance = pointToLineDistance(xx, yy, x1, y1, x2, y2);
            float distance = maxDistance - lineDistance;
            assert(distance >= 0.0f);
            //distance = tan(distance) * 2;
            size_t valIdx = xx + yy * width;
            float writeDistance = distance / width;
            if(writeDistance > additionVals[valIdx]){
                additionVals[valIdx] = writeDistance;
            }
        }
    }

    GenerateAdditionLayerMapGenStep::GenerateAdditionLayerMapGenStep() : MapGenStep("Generate Addition Layer"){

    }

    GenerateAdditionLayerMapGenStep::~GenerateAdditionLayerMapGenStep(){

    }

    bool GenerateAdditionLayerMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<float> additionVals;
        additionVals.resize(mapData->width * mapData->height);

        for(int i = 0; i < workspace->blobSeeds.size()-1; i++){
            calculateLines_(i, additionVals, mapData, workspace->blobSeeds);
        }
        calculateBlobs_(additionVals, mapData, workspace->blobSeeds);

        workspace->additionLayer = std::move(additionVals);

        return true;
    }
}
