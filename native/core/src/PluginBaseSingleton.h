#pragma once

namespace ProceduralExplorationGameCore {
    class MapGen;
    class VisitedPlacesParser;
    class MapGenScriptManager;
    class PlacedItemManager;
}

namespace ProceduralExplorationGameCore {

    class PluginBaseSingleton {

    public:
        static ProceduralExplorationGameCore::MapGen* getMapGen();
        static ProceduralExplorationGameCore::VisitedPlacesParser* getVisitedPlacesParser();
        static ProceduralExplorationGameCore::MapGenScriptManager* getScriptManager();
        static ProceduralExplorationGameCore::PlacedItemManager* getPlacedItemManager();

        static void initialise(
            ProceduralExplorationGameCore::MapGen* mapGen,
            ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
            ProceduralExplorationGameCore::MapGenScriptManager* scriptManager,
            ProceduralExplorationGameCore::PlacedItemManager* placedItemManager
        );

    private:

        static ProceduralExplorationGameCore::MapGen* mCurrentMapGen;
        static ProceduralExplorationGameCore::VisitedPlacesParser* mCurrentVisitedPlacesParser;
        static ProceduralExplorationGameCore::MapGenScriptManager* mScriptManager;
        static ProceduralExplorationGameCore::PlacedItemManager* mPlacedItemManager;
    };

} // namespace ProceduralExplorationGameCore
