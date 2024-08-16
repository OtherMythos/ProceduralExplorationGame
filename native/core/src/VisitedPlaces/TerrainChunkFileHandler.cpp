#include "TerrainChunkFileHandler.h"

#include "System/EnginePrerequisites.h"
#include "System/Util/PathUtils.h"
#include "VisitedPlacesPrerequisites.h"

#include "GameCoreLogger.h"

#include <fstream>
#include <sstream>
#include <vector>

namespace ProceduralExplorationGameCore{

    TerrainChunkFileHandler::TerrainChunkFileHandler(const std::string& mapsDir) :
        mMapsDir(mapsDir)
    {

    }

    TerrainChunkFileHandler::~TerrainChunkFileHandler(){

    }

    bool TerrainChunkFileHandler::parseFileToData_(VisitedPlaceMapData* outData, const std::string& filePath, bool altitudeDestination) const{
        outData->altitudeValues.clear();

        size_t activeWidth = 0;
        size_t height = 0;

        std::stringstream ss;

        std::string line;
        std::ifstream myfile(filePath);
        if(!myfile.is_open()){
            return false;
        }

        std::vector<AV::uint8>& destination = altitudeDestination ? outData->altitudeValues : outData->voxelValues;

        while(getline(myfile, line)){
            size_t width = 0;
            for(size_t i = 0; i < line.size(); i++){
                const char c = line.at(i);
                if(c == ','){
                    int outValue = std::stoi(ss.str());
                    destination.push_back(static_cast<AV::uint8>(outValue));
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

        outData->width = static_cast<AV::uint32>(activeWidth);
        outData->height = static_cast<AV::uint32>(height);

        return true;
    }

    bool TerrainChunkFileHandler::readMapDataFile_(VisitedPlaceMapData* outData, const std::string& resolvedMapsDir, const char* fileName, bool altitudeDestination, const std::string& mapName) const{
        std::filesystem::path p(resolvedMapsDir);
        p = p / mapName / fileName;
        if(std::filesystem::exists(p)){
            bool result = parseFileToData_(outData, p.string(), altitudeDestination);
            if(!result){
                GAME_CORE_ERROR("Unable to parse file '{}' for map '{}'", fileName, mapName);
                return false;
            }
        }
        return true;
    }

    bool TerrainChunkFileHandler::readMapData(VisitedPlaceMapData* outData, const std::string& mapName) const{
        std::string outPath;
        AV::formatResToPath(mMapsDir, outPath);

        if(!readMapDataFile_(outData, outPath, "terrain.txt", true, mapName)) return false;
        if(!readMapDataFile_(outData, outPath, "terrainBlend.txt", false, mapName)) return false;

        if(outData->altitudeValues.size() != outData->voxelValues.size()) return false;

        return true;
    }

}
