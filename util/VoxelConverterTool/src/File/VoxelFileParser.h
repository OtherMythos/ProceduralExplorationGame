#pragma once

#include "Prerequisites.h"

#include <string>
#include <map>
#include <vector>

namespace VoxelConverterTool{

    struct ParsedVoxFile{
        //Data of size 256*256*256.
        std::vector<VoxelId> data;
        //Bounds
        int minX, minY, minZ;
        int maxX, maxY, maxZ;
    };

    class VoxelFileParser{
    public:
        VoxelFileParser();
        ~VoxelFileParser();

        bool parseFile(const std::string& filePath, ParsedVoxFile& outData);


    private:
        typedef unsigned int VoxHex;

        struct ParsedVoxel{
            VoxelId vox;
            int x, y, z;
        };

        void _parseLineToData(const std::string& line, ParsedVoxel& vox);
        VoxelId _parseHexToVoxel(const std::string& hexValue);

        std::map<VoxHex, VoxelId> mResolvedVoxels;
    };
}
