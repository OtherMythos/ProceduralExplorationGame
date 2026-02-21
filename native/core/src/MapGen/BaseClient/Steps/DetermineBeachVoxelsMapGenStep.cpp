#include "DetermineBeachVoxelsMapGenStep.h"

#include <stack>
#include <vector>

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace ProceduralExplorationGameCore{

    DetermineBeachVoxelsMapGenStep::DetermineBeachVoxelsMapGenStep() : MapGenStep("Determine Beach Voxels"){

    }

    DetermineBeachVoxelsMapGenStep::~DetermineBeachVoxelsMapGenStep(){

    }

    bool DetermineBeachVoxelsMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        const AV::uint32 width = mapData->width;
        const AV::uint32 height = mapData->height;

        auto isOceanWaterGroup = [](AV::uint8 wGroup) -> bool {
            return wGroup == 0;
        };

        const std::vector<RegionData>& regionData = *mapData->ptr<std::vector<RegionData>>("regionData");

        auto isSandVoxel = [](const ExplorationMapData* md, WorldPoint p) -> bool {
            return *VOX_VALUE_PTR_FOR_COORD_CONST(md, p) == static_cast<AV::uint8>(MapVoxelTypes::SAND);
        };

        auto isGrasslandVoxel = [&regionData](const ExplorationMapData* md, WorldPoint p) -> bool {
            RegionId regionId = *REGION_PTR_FOR_COORD_CONST(md, p);
            if(regionId >= regionData.size()) return false;
            return regionData[regionId].type == RegionType::GRASSLAND || regionData[regionId].type == RegionType::NONE;
        };

        static const int DX[4] = {-1, 1, 0, 0};
        static const int DY[4] = {0, 0, -1, 1};

        std::vector<bool> visited(width * height, false);
        std::stack<WorldPoint> floodStack;

        //Find seed voxels: sand tiles adjacent to at least one ocean water voxel.
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                WorldPoint p = WRAP_WORLD_POINT(x, y);
                if(!isSandVoxel(mapData, p)) continue;
                if(!isGrasslandVoxel(mapData, p)) continue;

                for(int d = 0; d < 4; d++){
                    int nx = static_cast<int>(x) + DX[d];
                    int ny = static_cast<int>(y) + DY[d];
                    if(nx < 0 || ny < 0 || nx >= static_cast<int>(width) || ny >= static_cast<int>(height)) continue;
                    AV::uint8 wGroup = *WATER_GROUP_PTR_FOR_COORD(mapData, WRAP_WORLD_POINT(nx, ny));
                    if(isOceanWaterGroup(wGroup)){
                        floodStack.push(p);
                        break;
                    }
                }
            }
        }

        //Flood fill through connected sand voxels, marking each as a beach.
        while(!floodStack.empty()){
            WorldPoint p = floodStack.top();
            floodStack.pop();

            WorldCoord x, y;
            READ_WORLD_POINT(p, x, y);
            size_t idx = x + static_cast<size_t>(y) * width;

            if(visited[idx]) continue;
            visited[idx] = true;

            if(!isSandVoxel(mapData, p)) continue;
            if(!isGrasslandVoxel(mapData, p)) continue;

            VOXEL_FLAGS_ADD(mapData, p, BEACH_VOXEL_FLAG);

            for(int d = 0; d < 4; d++){
                int nx = static_cast<int>(x) + DX[d];
                int ny = static_cast<int>(y) + DY[d];
                if(nx < 0 || ny < 0 || nx >= static_cast<int>(width) || ny >= static_cast<int>(height)) continue;
                size_t nidx = nx + ny * width;
                if(!visited[nidx]){
                    floodStack.push(WRAP_WORLD_POINT(nx, ny));
                }
            }
        }

        return true;
    }

}
