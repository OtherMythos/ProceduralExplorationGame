#pragma once

#include "Prerequisites.h"

#include <string>
#include <map>
#include <vector>

namespace VoxelConverterTool{

    struct ParsedVoxFile;

    struct OutputFaces{
        std::vector<WrappedFace> outFaces;
        float minX, minY, minZ;
        float maxX, maxY, maxZ;

        size_t calcMeshSizeBytes() const{
            return outFaces.size() * 4 * 6 * sizeof(uint32);
        }
    };

    class VoxToFaces{
    public:
        VoxToFaces();
        ~VoxToFaces();

        void voxToFaces(const ParsedVoxFile& parsedVox, OutputFaces& faces);

    private:
        VoxelId readVoxelFromData_(const ParsedVoxFile& parsedVox, int x, int y, int z);
        uint8 getNeighbourMask(const ParsedVoxFile& parsedVox, int x, int y, int z);
        uint32 getVerticeBorder(const ParsedVoxFile& parsedVox, uint8 f, int x, int y, int z);
    };
}
