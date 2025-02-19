#include "DataPointFileHandler.h"

#include "System/EnginePrerequisites.h"
#include "System/Util/PathUtils.h"
#include "VisitedPlacesPrerequisites.h"

#include "GameCoreLogger.h"

#include <fstream>
#include <sstream>
#include <vector>
#include <filesystem>
#include <regex>

namespace ProceduralExplorationGameCore{

    DataPointFileHandler::DataPointFileHandler(const std::string& mapsDir) :
        mMapsDir(mapsDir)
    {

    }

    DataPointFileHandler::~DataPointFileHandler(){

    }

    bool DataPointFileHandler::parseLineForFile_(std::vector<ProceduralExplorationGameCore::DataPointData>& outVec, const std::string& line) const{
        std::stringstream ss;

        float vals[3];
        int count = 0;
        DataPointData d;
        for(size_t i = 0; i < line.size(); i++){
            const char c = line.at(i);
            if(c == ','){
                float outValue = std::stof(ss.str());
                assert(count < sizeof(vals) / sizeof(float));
                vals[count] = outValue;
                count++;
                ss.str(std::string());
                continue;
            }
            ss << c;
        }

        const std::string dataVals = ss.str();

        static const std::regex lineRegex("^\\d+-\\d+$");
        if(!std::regex_match(dataVals, lineRegex)){
            return false;
        }

        int num1, num2;
        char semi;
        ss >> num1 >> semi >> num2 >> semi;

        DataPointWrapped wrappedData = AV::uint32(AV::uint16(num1)) << 16 | AV::uint16(num2);

        outVec.push_back({vals[0], vals[1], vals[2], wrappedData});

        return true;
    }

    bool DataPointFileHandler::readData(std::vector<ProceduralExplorationGameCore::DataPointData>& outVec, const std::string& filePath) const{
        if(!std::filesystem::exists(filePath)){
            return false;
        }

        std::string line;
        std::ifstream myfile(filePath);
        if(!myfile.is_open()){
            return false;
        }

        while(getline(myfile, line)){
            bool result = parseLineForFile_(outVec, line);
            if(!result) return result;
        }
    }

    bool DataPointFileHandler::readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const{
        std::string outPath;
        AV::formatResToPath(mMapsDir, outPath);

        std::filesystem::path p(outPath);
        p = p / mapName / "dataPoints.txt";

        return readData(outData->dataPointValues, p.string());
    }

}
