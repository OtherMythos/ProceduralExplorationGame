#include "CalculateRegionConcavityMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cassert>
#include <cmath>
#include <algorithm>

namespace ProceduralExplorationGameCore{

    CalculateRegionConcavityMapGenStep::CalculateRegionConcavityMapGenStep() : MapGenStep("Calculate Region Concavity"){

    }

    CalculateRegionConcavityMapGenStep::~CalculateRegionConcavityMapGenStep(){

    }

    //Calculate the cross product of vectors OA and OB
    static float crossProduct(float ox, float oy, float ax, float ay, float bx, float by){
        return (ax - ox) * (by - oy) - (ay - oy) * (bx - ox);
    }

    //Graham scan algorithm to find convex hull
    static std::vector<std::pair<float, float>> computeConvexHull(std::vector<std::pair<float, float>>& points){
        if(points.size() <= 3){
            return points;
        }

        //Sort points lexicographically
        std::sort(points.begin(), points.end());

        //Build lower hull
        std::vector<std::pair<float, float>> lower;
        for(const auto& p : points){
            while(lower.size() >= 2 && crossProduct(lower[lower.size()-2].first, lower[lower.size()-2].second, lower[lower.size()-1].first, lower[lower.size()-1].second, p.first, p.second) <= 0.0f){
                lower.pop_back();
            }
            lower.push_back(p);
        }

        //Build upper hull
        std::vector<std::pair<float, float>> upper;
        for(int i = static_cast<int>(points.size()) - 1; i >= 0; i--){
            const auto& p = points[i];
            while(upper.size() >= 2 && crossProduct(upper[upper.size()-2].first, upper[upper.size()-2].second, upper[upper.size()-1].first, upper[upper.size()-1].second, p.first, p.second) <= 0.0f){
                upper.pop_back();
            }
            upper.push_back(p);
        }

        //Remove last point of each half because it's repeated
        lower.pop_back();
        upper.pop_back();

        //Concatenate
        lower.insert(lower.end(), upper.begin(), upper.end());

        return lower;
    }

    //Calculate area using shoelace formula
    static float calculatePolygonArea(const std::vector<std::pair<float, float>>& polygon){
        if(polygon.size() < 3) return 0.0f;

        float area = 0.0f;
        for(size_t i = 0; i < polygon.size(); i++){
            size_t j = (i + 1) % polygon.size();
            area += polygon[i].first * polygon[j].second;
            area -= polygon[j].first * polygon[i].second;
        }
        return std::abs(area) / 2.0f;
    }

    //Calculate perimeter by counting exposed edges
    static float calculatePerimeter(const std::vector<std::pair<float, float>>& polygon){
        if(polygon.size() < 2) return 0.0f;

        float perimeter = 0.0f;
        for(size_t i = 0; i < polygon.size(); i++){
            size_t j = (i + 1) % polygon.size();
            float dx = polygon[j].first - polygon[i].first;
            float dy = polygon[j].second - polygon[i].second;
            perimeter += std::sqrt(dx * dx + dy * dy);
        }
        return perimeter;
    }

    static float calculateRegionConcavity(const RegionData& region){
        if(region.coords.empty()){
            return 0.0f;
        }

        //Step 1: Gather basic shape data
        AV::uint32 area = region.total;

        //Find bounding box
        float minX = std::numeric_limits<float>::max();
        float maxX = std::numeric_limits<float>::lowest();
        float minY = std::numeric_limits<float>::max();
        float maxY = std::numeric_limits<float>::lowest();

        std::vector<std::pair<float, float>> boundaryPoints;

        for(WorldPoint wp : region.edges){
            WorldCoord x, y;
            READ_WORLD_POINT(wp, x, y);

            float fx = static_cast<float>(x);
            float fy = static_cast<float>(y);

            minX = std::min(minX, fx);
            maxX = std::max(maxX, fx);
            minY = std::min(minY, fy);
            maxY = std::max(maxY, fy);

            boundaryPoints.push_back({fx, fy});
        }

        if(boundaryPoints.empty()){
            return 0.0f;
        }

        //Step 2: Measure squareness/compactness
        float boundingBoxWidth = maxX - minX + 1.0f;
        float boundingBoxHeight = maxY - minY + 1.0f;
        float boundingBoxArea = boundingBoxWidth * boundingBoxHeight;

        float squareFactor = static_cast<float>(area) / boundingBoxArea;

        //Calculate perimeter-based compactness
        //Count exposed edges from boundary
        float perimeter = static_cast<float>(region.edges.size());

        //Isoperimetric ratio: 4π × area / perimeter²
        float compactness = 1.0f;
        if(perimeter > 0.0f){
            compactness = (4.0f * 3.14159265359f * area) / (perimeter * perimeter);
            //Normalize to ~1.0 for perfect circle/square
            compactness = std::min(compactness, 1.0f);
        }

        //Step 3: Measure concavity
        //Compute convex hull
        std::vector<std::pair<float, float>> hullPoints = computeConvexHull(boundaryPoints);

        float convexHullArea = calculatePolygonArea(hullPoints);
        if(convexHullArea <= 0.0f){
            convexHullArea = 1.0f;
        }

        //Concavity = filled area / convex hull area
        float concavity = static_cast<float>(area) / convexHullArea;
        concavity = std::min(concavity, 1.0f);

        //Step 4: Combine into single score
        //Using geometric mean weighted towards concavity
        float finalScore = squareFactor * concavity;

        return finalScore;
    }

    bool CalculateRegionConcavityMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::vector<RegionData>& regionData = (*mapData->ptr<std::vector<RegionData>>("regionData"));

        for(RegionData& region : regionData){
            float concavity = calculateRegionConcavity(region);
            //Store concavity in the meta field (0-255 range)
            region.concavity = static_cast<AV::uint8>(concavity * 255.0f);
        }

        return true;
    }

}
