#include "GameplayState.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

   std::vector<bool> GameplayState::mFoundRegions;

    void GameplayState::setNewMapData(ExplorationMapData* mapData){
        mFoundRegions.resize(mapData->regionData.size(), false);
        std::fill(mFoundRegions.begin(), mFoundRegions.end(), false);
    }

}
