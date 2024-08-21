#pragma once

#include "Prerequisites.h"

#include <string>
#include <map>

namespace VoxelConverterTool{

    struct ParsedVoxFile;

    class VoxToFaces{
    public:
        VoxToFaces();
        ~VoxToFaces();

        void voxToFaces(const ParsedVoxFile& parsedVox, std::vector<WrappedFace>& outFaces);

    private:
        VoxelId readVoxelFromData_(const ParsedVoxFile& parsedVox, int x, int y, int z);
        uint8 getNeighbourMask(const ParsedVoxFile& parsedVox, int x, int y, int z);
        uint32 getVerticeBorder(const ParsedVoxFile& parsedVox, uint8 f, int x, int y, int z);
    };
}
