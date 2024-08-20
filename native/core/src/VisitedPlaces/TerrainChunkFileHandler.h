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
        template <typename T>
        bool parseFileToData_(VisitedPlaceMapData* outData, const std::string& filePath, std::vector<T>& destination) const;
        template <typename T>
        bool readMapDataFile_(VisitedPlaceMapData* outData, const std::string& resolvedMapsDir, const char* fileName, std::vector<T>& destination, const std::string& mapName) const;

    private:
        std::string mMapsDir;
    };
}
