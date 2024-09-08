#include "VoxToFaces.h"

#include "File/VoxelFileParser.h"

#include "VoxData.h"

#include <iostream>

namespace VoxelConverterTool{

    VoxToFaces::VoxToFaces(){

    }

    VoxToFaces::~VoxToFaces(){

    }

    VoxelId VoxToFaces::readVoxelFromData_(const ParsedVoxFile& parsedVox, int x, int y, int z){
        return parsedVox.data[x + (y * 256) + (z * 256 * 256)];
    }

    uint32 VoxToFaces::getVerticeBorder(const ParsedVoxFile& parsedVox, uint8 f, int x, int y, int z){
        uint32 faceVal = f * 9 * 4;
        uint32 ret = 0;
        for(uint8 v = 0; v < 4; v++){
            uint32 faceBase = faceVal + v * 9;
            uint8 foundValsTemp[3] = {0, 0, 0};
            for(uint8 i = 0; i < 3; i++){
                int xx = VERTICE_BORDERS[faceBase + i * 3];
                int yy = VERTICE_BORDERS[faceBase + i * 3 + 1];
                int zz = VERTICE_BORDERS[faceBase + i * 3 + 2];

                int xPos = x + xx;
                if(x < 0 || xPos >= 255) continue;
                int yPos = y + yy;
                if(yPos < 0 || yPos >= 255) continue;
                int zPos = z + zz;
                if(zPos < 0 || zPos >= 255) continue;

                VoxelId vox = readVoxelFromData_(parsedVox, xPos, yPos, zPos);
                foundValsTemp[i] = vox != EMPTY_VOXEL ? 1 : 0;
            }
            //https://0fps.net/2013/07/03/ambient-occlusion-for-minecraft-like-worlds/
            uint32 val = 0;
            if(foundValsTemp[0] && foundValsTemp[1]){
                val = 0;
            }else{
                val = 3 - (foundValsTemp[0] + foundValsTemp[1] + foundValsTemp[2]);
            }
            //Batch the results for all 4 vertices into the single return value.
            ret = ret | val << (v * 4);
        }
        return ret;
    }

    inline bool blockIsFaceVisible(uint8 mask, int f){
        return 0 == ((1 << f) & mask);
    }
    uint8 VoxToFaces::getNeighbourMask(const ParsedVoxFile& parsedVox, int x, int y, int z){
        uint8 ret = 0;
        for(uint8 v = 0; v < 6; v++){
            int xx = MASKS[v * 3];
            int yy = MASKS[v * 3 + 1];
            int zz = MASKS[v * 3 + 2];

            int xPos = x + xx;
            if(x < 0 || xPos >= 255) continue;
            int yPos = y + yy;
            if(yPos < 0 || yPos >= 255) continue;
            int zPos = z + zz;
            if(zPos < 0 || zPos >= 255) continue;

            VoxelId vox = readVoxelFromData_(parsedVox, xPos, yPos, zPos);
            if(vox != EMPTY_VOXEL){
                ret = ret | (1 << v);
            }
        }
        return ret;
    }

    void VoxToFaces::voxToFaces(const ParsedVoxFile& parsedVox, OutputFaces& faces){
        //Recalculate the max and min incase some faces have been removed.
        int currentMinX, currentMinY, currentMinZ;
        int currentMaxX, currentMaxY, currentMaxZ;
        currentMinX = currentMinY = currentMinZ = 128;
        currentMaxX = currentMaxY = currentMaxZ = 128;

        int width = parsedVox.maxX - parsedVox.minX;
        int height = parsedVox.maxY - parsedVox.minY;
        for(int z = parsedVox.minZ; z <= parsedVox.maxZ; z++)
        for(int y = parsedVox.minY; y <= parsedVox.maxY; y++)
        for(int x = parsedVox.minX; x <= parsedVox.maxX; x++){
            VoxelId v = readVoxelFromData_(parsedVox, x, y, z);
            if(v == EMPTY_VOXEL) continue;
            uint8 neighbourMask = getNeighbourMask(parsedVox, x, y, z);
            for(int f = 0; f < 6; f++){
                if(!blockIsFaceVisible(neighbourMask, f)) continue;
                uint32 ambientMask = getVerticeBorder(parsedVox, f, x, y, z);
                //Submit this face

                const WrappedFaceContainer c = {x, y, z, v, ambientMask, f};
                WrappedFace face = _wrapFace(c);
                faces.outFaces.push_back(face);
            }
            if(x < currentMinX) currentMinX = x;
            if(y < currentMinY) currentMinY = y;
            if(z < currentMinZ) currentMinZ = z;

            if(x > currentMaxX) currentMaxX = x;
            if(y > currentMaxY) currentMaxY = y;
            if(z > currentMaxZ) currentMaxZ = z;
        }

        faces.minX = currentMinX;
        faces.minY = currentMinY;
        faces.minZ = currentMinZ;
        faces.maxX = currentMaxX;
        faces.maxY = currentMaxY;
        faces.maxZ = currentMaxZ;
    }

}
