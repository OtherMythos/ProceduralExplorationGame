#pragma once

#include <string>
#include <vector>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;

    class DataPointFileHandler{
    public:
        DataPointFileHandler(const std::string& mapsDir);
        ~DataPointFileHandler();

        bool readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const;

    private:
        std::string mMapsDir;

        bool parseLineForFile_(VisitedPlaceMapData* outData, const std::string& line) const;
    };
}
