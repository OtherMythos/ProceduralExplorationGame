#include "VoxelFileParser.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <regex>

#include "PaletteValues.h"

namespace VoxelConverterTool{

    VoxelFileParser::VoxelFileParser(){
        for(VoxelId v = 0; v < PALETTE.size(); v++){
            mResolvedVoxels[PALETTE[v]] = v;
        }
    }

    VoxelFileParser::~VoxelFileParser(){

    }

    VoxelId VoxelFileParser::_parseHexToVoxel(const std::string& hexValue){
        std::stringstream ss;
        ss << std::hex << hexValue;

        unsigned int out;
        ss >> out;

        return mResolvedVoxels[out];
    }

    void VoxelFileParser::_parseLineToData(const std::string& line, ParsedVoxel& vox){
        int count = 0;
        std::stringstream ss;

        for(size_t i = 0; i < line.size(); i++){
            const char c = line.at(i);
            ss << c;
            if(c == ' ' || i == line.size()-1){
                if(count == 0){
                    vox.x = std::stoi(ss.str());
                }
                else if(count == 1){
                    vox.y = std::stoi(ss.str());
                }
                else if(count == 2){
                    vox.z = std::stoi(ss.str());
                }
                else if(count == 3){
                    vox.vox = _parseHexToVoxel(ss.str());
                }
                ss.str(std::string());
                count++;
                continue;
            }
        }

    }

    bool VoxelFileParser::parseFile(const std::string& filePath, ParsedVoxFile& outData){
        std::string line;
        std::ifstream myfile(filePath);
        if(!myfile.is_open()){
            return false;
        }

        static const std::regex lineRegex("^-?\\d+ -?\\d+ -?\\d+ \\w{6}$");

        std::vector<VoxelId> voxData;
        voxData.resize(256 * 256 * 256, EMPTY_VOXEL);

        static const int INVALID_POS = -100;
        int minX = INVALID_POS;
        int minY = INVALID_POS;
        int minZ = INVALID_POS;
        int maxX = INVALID_POS;
        int maxY = INVALID_POS;
        int maxZ = INVALID_POS;

        while(getline(myfile, line)){
            if(line.at(0) == '#') continue;

            if(!std::regex_match(line, lineRegex)){
                std::cout << "Entry in voxel file corrupt" << std::endl;
                return false;
            }

            ParsedVoxel v = {0, 0, 0, 0};
            _parseLineToData(line, v);

            int vY = v.y;
            v.y = v.z;
            v.z = -vY;

            //Determine the bounds.
            int xx = v.x + 128;
            int yy = v.y + 128;
            int zz = v.z + 128;

            if(xx < minX || minX == INVALID_POS) minX = xx;
            if(yy < minY || minY == INVALID_POS) minY = yy;
            if(zz < minZ || minZ == INVALID_POS) minZ = zz;

            if(xx > maxX || minX == INVALID_POS) maxX = xx;
            if(yy > maxY || minY == INVALID_POS) maxY = yy;
            if(zz > maxZ || minZ == INVALID_POS) maxZ = zz;

            if(
               xx >= 256 || yy >= 256 || zz >= 256 ||
               xx < 0 || yy < 0 || zz < 0
               ){
                   continue;
               }

            voxData[xx + (yy * 256) + (zz * 256 * 256)] = v.vox;
        }

        outData.data = std::move(voxData);
        outData.minX = _clampMaxMin(minX);
        outData.minY = _clampMaxMin(minY);
        outData.minZ = _clampMaxMin(minZ);
        outData.maxX = _clampMaxMin(maxX);
        outData.maxY = _clampMaxMin(maxY);
        outData.maxZ = _clampMaxMin(maxZ);

        return true;
    }

    int VoxelFileParser::_clampMaxMin(int val) const{
        if(val < 0) return 0;
        if(val >= 0xFF) return 0xFF-1;
        return val;
    }
}
