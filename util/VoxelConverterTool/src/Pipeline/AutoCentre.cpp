#include "AutoCentre.h"

#include "File/VoxelFileParser.h"
#include <cmath>

namespace VoxelConverterTool{

    AutoCentre::AutoCentre(){

    }

    AutoCentre::~AutoCentre(){

    }

    void AutoCentre::centreForParsedFile(ParsedVoxFile& p){
        int deltaX = p.maxX - p.minX;
        int deltaZ = p.maxZ - p.minZ;
        int sizeX = floor(deltaX / 2);
        int sizeZ = floor(deltaZ / 2);
        int midX = p.maxX - sizeX;
        int midZ = p.maxZ - sizeZ;
        int shiftX = midX - 128;
        int shiftZ = midZ - 128;

        if(shiftX == 0 && shiftZ == 0){
            return;
        }

        std::vector<VoxelId> temp(p.data.size(), EMPTY_VOXEL);

        int width = 256;
        int height = 256;
        int depth = 256;
        for(int z = 0; z < height; z++){
            for(int y = 0; y < depth; y++){
                for(int x = 0; x < width; x++){
                    int newX = (x + -shiftX + width) % width;
                    int newZ = (z + -shiftZ + height) % height;

                    //TODO check and remove this
                    bool thing = false;
                    if(p.data[x + (z * width) + (y * width * height)] != EMPTY_VOXEL){
                        thing = true;
                    }
                    // Set the pixel in the new position
                    temp[newX + (y * width) + (newZ * width * height)] = p.data[x + (y * width) + (z * width * height)];
                }
            }
        }

        p.minX -= shiftX;
        p.maxX -= shiftX;
        p.minZ -= shiftZ;
        p.maxZ -= shiftZ;

        p.data = std::move(temp);
    }

}
