#pragma once

#include "MapGen/ExplorationMapDataPrerequisites.h"

namespace ProceduralExplorationGameCore{

    class ExplorationMapData;

    class OverworldMapTextureGenerator{
    public:
        OverworldMapTextureGenerator();
        ~OverworldMapTextureGenerator();

        void generateTexture(ExplorationMapData* mapData);

    private:
        void generateWaterTextureBuffers(ExplorationMapData* mapData);
    };

}
