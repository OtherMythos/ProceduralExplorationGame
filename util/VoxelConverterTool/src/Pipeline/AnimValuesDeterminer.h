#pragma once

#include "Prerequisites.h"

namespace VoxelConverterTool{

    struct ParsedVoxFile;

    class AnimValuesDeterminer{
    public:
        AnimValuesDeterminer();
        ~AnimValuesDeterminer();

        void determineAnimValuesForFaces(OutputFaces& faces, const std::vector<ParamAnimVoxel>& animValues);

    private:
        VoxelAnimValue _getAnimValueForVoxel(const std::vector<ParamAnimVoxel>& vecValues, VoxelId voxel);
    };

}
