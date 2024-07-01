#pragma once

namespace Ogre{
    class TextureBox;
}

namespace ProceduralExplorationGameCore{

    struct ExplorationMapData;

    class ExplorationMapViewer{
    public:
        ExplorationMapViewer();
        ~ExplorationMapViewer();

        void fillStagingTexture(Ogre::TextureBox* tex, ExplorationMapData* mapData);
    };

}
