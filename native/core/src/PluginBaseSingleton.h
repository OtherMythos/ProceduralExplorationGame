#pragma once

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore {
    class MapGen;
    class VisitedPlacesParser;
    class MapGenScriptManager;
}

namespace Ogre{
    class ConstBufferPacked;
}

namespace ProceduralExplorationGameCore {

    struct RegionBufferDataContainer{
        AV::uint8* buffer;
        Ogre::ConstBufferPacked* constBuffer;
    };

    class PluginBaseSingleton {

    public:
        static ProceduralExplorationGameCore::MapGen* getMapGen();
        static ProceduralExplorationGameCore::VisitedPlacesParser* getVisitedPlacesParser();
        static ProceduralExplorationGameCore::MapGenScriptManager* getScriptManager();
        static RegionBufferDataContainer getRegionBuffer();

        static void initialise(
            ProceduralExplorationGameCore::MapGen* mapGen,
            ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
            ProceduralExplorationGameCore::MapGenScriptManager* scriptManager,
            RegionBufferDataContainer regionBuffer
        );

    private:

        static ProceduralExplorationGameCore::MapGen* mCurrentMapGen;
        static ProceduralExplorationGameCore::VisitedPlacesParser* mCurrentVisitedPlacesParser;
        static ProceduralExplorationGameCore::MapGenScriptManager* mScriptManager;
        static RegionBufferDataContainer mRegionBuffer;
    };

} // namespace ProceduralExplorationGameCore
