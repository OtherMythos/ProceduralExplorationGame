#include "TileDataParser.h"

#include "System/EnginePrerequisites.h"
#include "System/Util/PathUtils.h"
#include "VisitedPlacesPrerequisites.h"

#include "GameCoreLogger.h"

#include <fstream>
#include <sstream>
#include <vector>
#include <filesystem>

#include "System/FileSystem/FilePath.h"
#include "System/Util/SimpleFileParser.h"

namespace ProceduralExplorationGameCore{

    TileDataParser::TileDataParser(const std::string& mapsDir) :
        mMapsDir(mapsDir)
    {

    }

    TileDataParser::~TileDataParser(){

    }

    bool TileDataParser::readData(OutDataContainer* outData, const std::string& mapName, const std::string& fileName) const{
        std::string outPath;
        AV::formatResToPath(mMapsDir, outPath);

        outData->tileValues.clear();

        if(!readMapDataFile_<OutDataContainer*, AV::uint8>(outData, outPath, fileName, outData->tileValues, mapName)) return false;

        return true;
    }

    template <typename D, typename T>
    bool TileDataParser::parseFileToData_(D outData, const std::string& filePath, std::vector<T>& destination) const{
        size_t activeWidth = 0;
        size_t height = 0;

        std::stringstream ss;

        AV::SimpleFileParser fileParser(filePath);
        if(!fileParser.isOpen()){
            return false;
        }

        std::string line;
        while(fileParser.getLine(line)){
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

    template <typename D, typename T>
    bool TileDataParser::readMapDataFile_(D outData, const std::string& resolvedMapsDir, const std::string& fileName, std::vector<T>& destination, const std::string& mapName) const{
        AV::FilePath p(resolvedMapsDir);
        p = p / AV::FilePath(mapName) / AV::FilePath(fileName);
        if(!p.exists()){
            GAME_CORE_ERROR("File at path '{}' does not exist.", p.string());
        }

        bool result = parseFileToData_<D, T>(outData, p.string(), destination);
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

        if(!readMapDataFile_<VisitedPlaceMapData*, TilePoint>(outData, outPath, "tileData.txt", outData->tileValues, mapName)) return false;

        return true;
    }

}
