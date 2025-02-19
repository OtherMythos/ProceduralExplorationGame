#pragma once

#include <string>
#include <vector>

namespace ProceduralExplorationGameCore{

    struct VisitedPlaceMapData;
    struct DataPointData;

    class DataPointFileHandler{
    public:
        DataPointFileHandler(const std::string& mapsDir);
        ~DataPointFileHandler();

        bool readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const;
        bool readData(std::vector<DataPointData>& outVec, const std::string& filePath) const;

    private:
        std::string mMapsDir;

        bool parseLineForFile_(std::vector<ProceduralExplorationGameCore::DataPointData>& outVec, const std::string& line) const;
    };
}
