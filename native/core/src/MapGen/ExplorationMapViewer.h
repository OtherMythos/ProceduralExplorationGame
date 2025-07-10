#pragma once

#include "System/EnginePrerequisites.h"

namespace Ogre{
    class TextureBox;
}

namespace ProceduralExplorationGameCore{

    class ExplorationMapData;

    class ExplorationMapViewer{
    public:
        ExplorationMapViewer();
        ~ExplorationMapViewer();

        void fillStagingTexture(Ogre::TextureBox* tex, ExplorationMapData* mapData);
        void fillStagingTextureComplex(Ogre::TextureBox* tex, ExplorationMapData* mapData, AV::uint32 drawOptions);
    };

}
