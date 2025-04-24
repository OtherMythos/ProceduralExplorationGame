#include "PluginBaseSingleton.h"

namespace ProceduralExplorationGameCore {

ProceduralExplorationGameCore::MapGen* PluginBaseSingleton::mCurrentMapGen = nullptr;
ProceduralExplorationGameCore::VisitedPlacesParser* PluginBaseSingleton::mCurrentVisitedPlacesParser = nullptr;
ProceduralExplorationGameCore::MapGenScriptManager* PluginBaseSingleton::mScriptManager = nullptr;

void PluginBaseSingleton::initialise(
    ProceduralExplorationGameCore::MapGen* mapGen,
    ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
    ProceduralExplorationGameCore::MapGenScriptManager* scriptManager
) {
    mCurrentMapGen = mapGen;
    mCurrentVisitedPlacesParser = visitedPlacesParser;
    mScriptManager = scriptManager;
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

} // namespace ProceduralExplorationGameCore
