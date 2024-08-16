#pragma once

#include <string>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;

    class TerrainChunkFileHandler{
    public:
        TerrainChunkFileHandler(const std::string& mapsDir);
        ~TerrainChunkFileHandler();

        bool readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const;

    private:
        bool parseFileToData_(VisitedPlaceMapData* outData, const std::string& filePath, bool altitudeDestination) const;
        bool readMapDataFile_(VisitedPlaceMapData* outData, const std::string& resolvedMapsDir, const char* fileName, bool altitudeDestination, const std::string& mapName) const;

    private:
        std::string mMapsDir;
    };
}
