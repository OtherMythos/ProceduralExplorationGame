#include "PluginBaseSingleton.h"

namespace ProceduralExplorationGameCore {

ProceduralExplorationGameCore::MapGen* PluginBaseSingleton::mCurrentMapGen = nullptr;
ProceduralExplorationGameCore::VisitedPlacesParser* PluginBaseSingleton::mCurrentVisitedPlacesParser = nullptr;
ProceduralExplorationGameCore::MapGenScriptManager* PluginBaseSingleton::mScriptManager = nullptr;
ProceduralExplorationGameCore::PlacedItemManager* PluginBaseSingleton::mPlacedItemManager = nullptr;

void PluginBaseSingleton::initialise(
    ProceduralExplorationGameCore::MapGen* mapGen,
    ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
    ProceduralExplorationGameCore::MapGenScriptManager* scriptManager,
    ProceduralExplorationGameCore::PlacedItemManager* placedItemManager
) {
    mCurrentMapGen = mapGen;
    mCurrentVisitedPlacesParser = visitedPlacesParser;
    mScriptManager = scriptManager;
    mPlacedItemManager = placedItemManager;
}

ProceduralExplorationGameCore::MapGen* PluginBaseSingleton::getMapGen() {
    return mCurrentMapGen;
}

ProceduralExplorationGameCore::VisitedPlacesParser* PluginBaseSingleton::getVisitedPlacesParser() {
    return mCurrentVisitedPlacesParser;
}

ProceduralExplorationGameCore::MapGenScriptManager* PluginBaseSingleton::getScriptManager() {
    return mScriptManager;
}

ProceduralExplorationGameCore::PlacedItemManager* PluginBaseSingleton::getPlacedItemManager() {
    return mPlacedItemManager;
}

} // namespace ProceduralExplorationGameCore
