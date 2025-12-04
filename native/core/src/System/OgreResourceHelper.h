#pragma once

#include "System/EnginePrerequisites.h"

#include <string>

namespace ProceduralExplorationGameCore{

    class OgreResourceHelper{
    public:
        OgreResourceHelper();
        ~OgreResourceHelper();

        void createTextureFromBuffer(const std::string& textureName, AV::uint32 width, AV::uint32 height, float* buffer);

    private:
        void destroyTextureIfExists(const std::string& textureName);
    };

}
