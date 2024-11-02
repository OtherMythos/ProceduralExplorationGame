#include "CarveRiversMapGenStep.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include "GameplayConstants.h"

#include <cassert>
#include <set>
#include <vector>

namespace ProceduralExplorationGameCore{

    CarveRiversMapGenStep::CarveRiversMapGenStep(){

    }

    CarveRiversMapGenStep::~CarveRiversMapGenStep(){

    }

    void CarveRiversMapGenStep::processStep(const ExplorationMapInputData* input, ExplorationMapData* mapData, ExplorationMapGenWorkspace* workspace){
        std::set<WorldPoint> writePoints;

        for(const RiverData& r : mapData->riverData){
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
            AV::uint32* worldPtr = FULL_PTR_FOR_COORD(mapData, p);
            *worldPtr |= (static_cast<AV::uint32>(MapVoxelTypes::RIVER) << 8);
        }
    }

}
