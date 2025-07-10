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

    private:
        //AV::uint32 getColourForVox(AV::uint32 x, AV::uint32 y, AV::uint32 vox, AV::uint32 secondaryVox, float blueNoise, ExplorationMapData* mapData, AV::uint32 drawOptions);
    };

}
