#pragma once

#include "GamePrerequisites.h"

#include <vector>

namespace ProceduralExplorationGameCore{

    class GameplayState{
    public:
        GameplayState() = delete;
        ~GameplayState() = delete;

        static void setNewMapData(ExplorationMapData* mapData);

        static ExplorationMapData* getMapData(){
            return mMapData;
        }

    private:
        static std::vector<bool> mFoundRegions;
        static ExplorationMapData* mMapData;

    public:
        static bool getFoundRegion(RegionId region){
            return mFoundRegions[region];
        }

        static void setRegionFound(RegionId region, bool found){
            mFoundRegions[region] = found;
        }
    };

}
