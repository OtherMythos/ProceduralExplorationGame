#include "DetermineRiversMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "GameplayConstants.h"

#include <cassert>
#include <set>
#include <vector>

namespace ProceduralExplorationGameCore{

    DetermineRiversMapGenStep::DetermineRiversMapGenStep() : MapGenStep("Determine Rivers"){

    }

    DetermineRiversMapGenStep::~DetermineRiversMapGenStep(){

    }

    WorldPoint _findPointOnCoast(const std::vector<FloodFillEntry*>& landData, LandId landId){
        const std::vector<WorldPoint>& edges = landData[landId]->edges;
        size_t randIndex = mapGenRandomIndex<WorldPoint>(edges);
        if(randIndex > edges.size()) return INVALID_WORLD_POINT;
        return edges[randIndex];
    }

    void _determineRiverOrigins(std::vector<WorldPoint>& out, const ExplorationMapInputData* input, const std::vector<FloodFillEntry*>& landData, const std::vector<LandId>& landWeighted, ExplorationMapData* data){
        out.reserve(input->uint32("numRivers"));
        //local origins = array(data.numRivers);
        for(int i = 0; i < input->uint32("numRivers"); i++){
            LandId landId = findRandomLandmassForSize(landData, landWeighted, 20);
            if(landId == INVALID_LAND_ID) continue;
            WorldPoint landPoint = _findPointOnCoast(landData, landId);
            if(landPoint == INVALID_WORLD_POINT) continue;
            if(*(FULL_PTR_FOR_COORD_SECONDARY(data, landPoint)) & DO_NOT_PLACE_RIVERS_VOXEL_FLAG){
                continue;
            }
            out.push_back(landPoint);
        }
    }

    struct MinNeighbourVal{
        int x;
        int y;
    };
    MinNeighbourVal _findMinNeighbourAltitude(int x, int y, void* voxBlob, ExplorationMapData* data){
        MinNeighbourVal checkValues[] = {
            {-1, 0},
            {+1, 0},
            {0, -1},
            {0, +1},

            {-1, -1},
            {+1, +1},
            {-1, -1},
            {+1, +1},
        };

        int min = 0;
        int minIdx = -1;
        for(int i = 0; i < 8; i++){
            const MinNeighbourVal& v = checkValues[i];
            AV::uint8 check = *ProceduralExplorationGameCore::VOX_PTR_FOR_COORD_CONST(data, ProceduralExplorationGameCore::WRAP_WORLD_POINT(x+v.x, y+v.y));
            if(check > min){
                min = check;
                minIdx = i;
            }
        }

        MinNeighbourVal retVal = checkValues[minIdx];
        retVal.x += x;
        retVal.y += y;
        return retVal;
    }

    void _calculateRivers(const std::vector<WorldPoint>& originData, void* noiseBlob, ExplorationMapData* data, std::vector<RiverData>& retData){
        for(int river = 0; river < originData.size(); river++){
            std::set<WorldPoint> altitudes;
            std::vector<WorldPoint> outData;
            WorldCoord originX, originY;
            READ_WORLD_POINT(originData[river], originX, originY);

            outData.push_back(WRAP_WORLD_POINT(originX, originY));

            WorldCoord currentX = originX;
            WorldCoord currentY = originY;
            for(int i = 0; i < 100; i++){
                MinNeighbourVal val = _findMinNeighbourAltitude(currentX, currentY, data->voxelBuffer, data);
                WorldPoint totalId = WRAP_WORLD_POINT(val.x, val.y);
                if(*(FULL_PTR_FOR_COORD_SECONDARY(data, totalId)) & DO_NOT_PLACE_RIVERS_VOXEL_FLAG){
                    continue;
                }
                if(altitudes.find(totalId) != altitudes.end()){
                    break;
                }
                currentX = val.x;
                currentY = val.y;
                altitudes.insert(totalId);
                outData.push_back(totalId);
            }
            if(outData.size() <= 15){
                //The river was too small.
                continue;
            }

            retData.push_back({ originData[river], std::move(outData) });
        }
    }

    void DetermineRiversMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const std::vector<FloodFillEntry*>& landData = (*mapData->ptr<std::vector<FloodFillEntry*>>("landData"));

        std::vector<WorldPoint> origins;
        //workspace.noise
        _determineRiverOrigins(origins, input, landData, workspace->landWeighted, mapData);
        std::vector<RiverData>* outData = new std::vector<RiverData>();
        _calculateRivers(origins, mapData->voxelBuffer, mapData, *outData);
        mapData->voidPtr("riverData", outData);
    }

}
