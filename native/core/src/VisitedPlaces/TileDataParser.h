#pragma once

#include <string>
#include <vector>

#include "System/EnginePrerequisites.h"

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;

    class TileDataParser{
    public:
        TileDataParser(const std::string& mapsDir);
        ~TileDataParser();

        struct OutDataContainer{
            std::vector<AV::uint8> tileValues;
            AV::uint32 tilesWidth, tilesHeight;
        };

        bool readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const;
        bool readData(OutDataContainer* outData, const std::string& mapName, const std::string& fileName) const;

    private:
        template <typename D, typename T>
        bool parseFileToData_(D outData, const std::string& filePath, std::vector<T>& destination) const;
        template <typename D, typename T>
        bool readMapDataFile_(D outData, const std::string& resolvedMapsDir, const std::string& fileName, std::vector<T>& destination, const std::string& mapName) const;

    private:
        std::string mMapsDir;
    };
}
