#pragma once

#include "Prerequisites.h"
#include <set>

namespace VoxelConverterTool{

    class FaceMerger{
    public:
        FaceMerger();
        ~FaceMerger();

        VoxelConverterTool::OutputFaces mergeFaces(const VoxelConverterTool::OutputFaces& faces);
    private:
        typedef uint64 FaceIntermediateWrapped;
        static const FaceIntermediateWrapped INVALID_FACE_INTERMEDIATE;
        struct FaceIntermediateContainer{
            VoxelId v;
            uint32 a;
        };
        static FaceIntermediateWrapped _wrapFaceIntermediate(const FaceIntermediateContainer& c){
            return
                static_cast<uint64>(c.v) |
                static_cast<uint64>(c.a) << 32;
        }

        static void _unwrapFaceIntermediate(FaceIntermediateWrapped f, FaceIntermediateContainer& o){
            o.v = f & 0xFFFF;
            o.a = (f >> 32) & 0xFFFF;
        }

        struct FaceVec3{
            int x, y, z;
        };
        static const FaceVec3 FACES_NORMALS[6];
        enum class FaceNormalType{
            X, Y, Z
        };
        static const FaceNormalType FACE_NORMAL_TYPES[6];

        void expand2DGrid(int z, FaceId f, const VoxelConverterTool::OutputFaces& inFaces, std::vector<FaceIntermediateWrapped>& wrapped, VoxelConverterTool::OutputFaces& outFaces);
        void expandFace(int& numFacesMerged, int aCoord, int bCoord, int gridSlice, int aSize, int bSize, FaceId f, FaceIntermediateContainer& fcc, const VoxelConverterTool::OutputFaces& faces, std::vector<FaceIntermediateWrapped>& wrapped, std::set<uint64>& intermediateFaces);

        void commitFaces(VoxelConverterTool::OutputFaces& faces, std::set<uint64>& intermediateFaces, FaceIntermediateContainer& fc, int gridSlice, FaceId f);

        int getDirectionAForNormalType(FaceNormalType ft) const;
        int getDirectionBForNormalType(FaceNormalType ft) const;

    };

}
