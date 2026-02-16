#include "CarveRiversMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include "GameplayConstants.h"

#include <cassert>
#include <set>
#include <vector>

namespace ProceduralExplorationGameCore{

    CarveRiversMapGenStep::CarveRiversMapGenStep() : MapGenStep("Carve Rivers"){

    }

    CarveRiversMapGenStep::~CarveRiversMapGenStep(){

    }

    bool CarveRiversMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::set<WorldPoint> writePoints;
        const std::vector<RiverData>* riverData = mapData->ptr<std::vector<RiverData>>("riverData");

        for(const RiverData& r : *riverData){
            writePoints.insert(r.origin);
            for(WorldPoint w : r.points){
                writePoints.insert(w);
                WorldCoord x, y;
                READ_WORLD_POINT(w, x, y);
                writePoints.insert(WRAP_WORLD_POINT(x-1, y));
                writePoints.insert(WRAP_WORLD_POINT(x+1, y));
                writePoints.insert(WRAP_WORLD_POINT(x, y-1));
                writePoints.insert(WRAP_WORLD_POINT(x, y+1));
            }
        }

        for(WorldPoint p : writePoints){
            AV::uint32* fullTertiary = FULL_PTR_FOR_COORD_TERTIARY(mapData, p);
            *fullTertiary |= RIVER_VOXEL_FLAG;
        }

        return true;
    }

}
