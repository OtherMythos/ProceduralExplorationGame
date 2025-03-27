#include "AnimValuesDeterminer.h"

#include "File/VoxelFileParser.h"
#include <cmath>

namespace VoxelConverterTool{

    AnimValuesDeterminer::AnimValuesDeterminer(){

    }

    AnimValuesDeterminer::~AnimValuesDeterminer(){

    }

    void AnimValuesDeterminer::determineAnimValuesForFaces(OutputFaces& faces, const std::vector<ParamAnimVoxel>& animValues){
        if(animValues.empty()){
            return;
        }

        for(WrappedFaceContainer& c : faces.outFaces){
            c.anim = _getAnimValueForVoxel(animValues, c.vox);
        }
    }

    VoxelAnimValue AnimValuesDeterminer::_getAnimValueForVoxel(const std::vector<ParamAnimVoxel>& vecValues, VoxelId voxel){
        for(const ParamAnimVoxel& p : vecValues){
            if(p.voxel == voxel){
                return p.value;
            }
        }

        return 0;
    }

}
