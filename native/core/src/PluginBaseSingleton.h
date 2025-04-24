#pragma once

namespace ProceduralExplorationGameCore {
    class MapGen;
    class VisitedPlacesParser;
    class MapGenScriptManager;
}

namespace ProceduralExplorationGameCore {

    class PluginBaseSingleton {

    public:
        static ProceduralExplorationGameCore::MapGen* getMapGen();
        static ProceduralExplorationGameCore::VisitedPlacesParser* getVisitedPlacesParser();
        static ProceduralExplorationGameCore::MapGenScriptManager* getScriptManager();

        static void initialise(
            ProceduralExplorationGameCore::MapGen* mapGen,
            ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
            ProceduralExplorationGameCore::MapGenScriptManager* scriptManager
        );

    private:

        static ProceduralExplorationGameCore::MapGen* mCurrentMapGen;
        static ProceduralExplorationGameCore::VisitedPlacesParser* mCurrentVisitedPlacesParser;
        static ProceduralExplorationGameCore::MapGenScriptManager* mScriptManager;
    };

} // namespace ProceduralExplorationGameCore
