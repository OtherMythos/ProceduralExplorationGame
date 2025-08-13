#include "PluginBaseSingleton.h"

namespace ProceduralExplorationGameCore {

ProceduralExplorationGameCore::MapGen* PluginBaseSingleton::mCurrentMapGen = nullptr;
ProceduralExplorationGameCore::VisitedPlacesParser* PluginBaseSingleton::mCurrentVisitedPlacesParser = nullptr;
ProceduralExplorationGameCore::MapGenScriptManager* PluginBaseSingleton::mScriptManager = nullptr;
ProceduralExplorationGameCore::RegionBufferDataContainer PluginBaseSingleton::mRegionBuffer = {0, 0};

void PluginBaseSingleton::initialise(
    ProceduralExplorationGameCore::MapGen* mapGen,
    ProceduralExplorationGameCore::VisitedPlacesParser* visitedPlacesParser,
    ProceduralExplorationGameCore::MapGenScriptManager* scriptManager,
    RegionBufferDataContainer regionBuffer
) {
    mCurrentMapGen = mapGen;
    mCurrentVisitedPlacesParser = visitedPlacesParser;
    mScriptManager = scriptManager;
    mRegionBuffer = regionBuffer;
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

RegionBufferDataContainer PluginBaseSingleton::getRegionBuffer(){
    return mRegionBuffer;
}

} // namespace ProceduralExplorationGameCore
