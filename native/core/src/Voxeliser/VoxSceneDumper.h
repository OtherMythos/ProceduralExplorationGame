#pragma once

#include <string>

namespace Ogre{
    class SceneNode;
}

namespace ProceduralExplorationGameCore{

    class VoxSceneDumper{
    public:
        VoxSceneDumper();
        ~VoxSceneDumper();

        void dumpToObjFile(const std::string& filePath, Ogre::SceneNode* node);

    };

}
