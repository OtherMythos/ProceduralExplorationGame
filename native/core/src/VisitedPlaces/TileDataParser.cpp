#include "TileDataParser.h"

#include "System/EnginePrerequisites.h"
#include "System/Util/PathUtils.h"
#include "VisitedPlacesPrerequisites.h"

#include "GameCoreLogger.h"

#include <fstream>
#include <sstream>
#include <vector>
#include <filesystem>

namespace ProceduralExplorationGameCore{

    TileDataParser::TileDataParser(const std::string& mapsDir) :
        mMapsDir(mapsDir)
    {

    }

    TileDataParser::~TileDataParser(){

    }

    template <typename T>
    bool TileDataParser::parseFileToData_(VisitedPlaceMapData* outData, const std::string& filePath, std::vector<T>& destination) const{
        size_t activeWidth = 0;
        size_t height = 0;

        std::stringstream ss;

        std::string line;
        std::ifstream myfile(filePath);
        if(!myfile.is_open()){
            return false;
        }

        while(getline(myfile, line)){
            size_t width = 0;
            for(size_t i = 0; i < line.size(); i++){
                const char c = line.at(i);
                if(c == ','){
                    int outValue = std::stoi(ss.str());
                    destination.push_back(static_cast<TilePoint>(outValue));
                    ss.str(std::string());
                    width++;
                    continue;
                }
                ss << c;
            }

            ss.str(std::string());
            if(activeWidth != width){
                //The width will be 0 to start.
                if(height != 0){
                    //Invalid height
                    return false;
                }
            }
            height++;
            activeWidth = width;
        }

        outData->tilesWidth = static_cast<AV::uint32>(activeWidth);
        outData->tilesHeight = static_cast<AV::uint32>(height);

        return true;
    }

    template <typename T>
    bool TileDataParser::readMapDataFile_(VisitedPlaceMapData* outData, const std::string& resolvedMapsDir, const char* fileName, std::vector<T>& destination, const std::string& mapName) const{
        std::filesystem::path p(resolvedMapsDir);
        p = p / mapName / fileName;
        if(!std::filesystem::exists(p)){
            GAME_CORE_ERROR("File at path '{}' does not exist.", p.string());
        }

        bool result = parseFileToData_<T>(outData, p.string(), destination);
        if(!result){
            GAME_CORE_ERROR("Unable to parse file '{}' for map '{}'", fileName, mapName);
            return false;
        }
        return true;
    }

    bool TileDataParser::readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const{
        std::string outPath;
        AV::formatResToPath(mMapsDir, outPath);

        outData->tileValues.clear();

        if(!readMapDataFile_<TilePoint>(outData, outPath, "tileData.txt", outData->tileValues, mapName)) return false;

        return true;
    }

}
