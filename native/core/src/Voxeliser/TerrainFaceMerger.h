#pragma once

#include "System/EnginePrerequisites.h"

#include <vector>
#include <set>

namespace ProceduralExplorationGameCore{

    typedef AV::uint16 VoxelId;
    static const VoxelId TERRAIN_EMPTY_VOXEL = 0x8000;
    typedef AV::uint64 WrappedFace;
    typedef AV::uint8 FaceId;
    typedef AV::uint8 RegionId;
    typedef AV::uint8 AmbientMask;
    typedef AV::uint8 VoxelAnimValue;
    static const FaceId MAX_FACES = 6;

    struct WrappedFaceContainer{
        AV::uint16 x, y, z;
        AV::uint8 sizeX, sizeY, sizeZ;
        VoxelId vox;
        AmbientMask ambientMask;
        AV::uint8 faceMask;
        VoxelAnimValue anim;
        AV::uint8 regionId;
    };
    struct OutputFaces{
        std::vector<WrappedFaceContainer> outFaces;
        int minX, minY, minZ;
        int maxX, maxY, maxZ;
        int deltaX, deltaY, deltaZ;

        size_t calcMeshSizeBytes() const{
            return outFaces.size() * 4 * 3 * sizeof(AV::uint32);
        }
    };
    static WrappedFace _wrapFace(const WrappedFaceContainer& c){
        return
            static_cast<AV::uint64>(c.x) |
            static_cast<AV::uint64>(c.y) << 8 |
            static_cast<AV::uint64>(c.z) << 16 |
            static_cast<AV::uint64>(c.vox) << 24 |
            static_cast<AV::uint64>(c.faceMask) << 32 |
            static_cast<AV::uint64>(c.ambientMask) << 35;
    }

    static void _unwrapFace(WrappedFace f, WrappedFaceContainer& o){
        o.x = f & 0xFF;
        o.y = (f >> 8) & 0xFF;
        o.z = (f >> 16) & 0xFF;
        o.vox = (f >> 24) & 0xFF;
        o.faceMask = (f >> 32) & 0x7;
        o.ambientMask = (f >> 35) & 0xFFFF;
    }

    typedef AV::uint8 FaceId;

    class TerrainFaceMerger{
    public:
        TerrainFaceMerger();
        ~TerrainFaceMerger();

        OutputFaces mergeFaces(const OutputFaces& faces);
    private:
        typedef AV::uint64 FaceIntermediateWrapped;
        static const FaceIntermediateWrapped INVALID_FACE_INTERMEDIATE;
        struct FaceIntermediateContainer{
            VoxelId v;
            AV::uint32 a;
            RegionId r;
        };
        static FaceIntermediateWrapped _wrapFaceIntermediate(const FaceIntermediateContainer& c){
            return
                static_cast<AV::uint64>(c.v) |
                static_cast<AV::uint64>(c.r) << 8 |
                static_cast<AV::uint64>(c.a) << 32;
        }

        static void _unwrapFaceIntermediate(FaceIntermediateWrapped f, FaceIntermediateContainer& o){
            o.v = f & 0xFF;
            o.r = (f >> 8) & 0xFF;
            o.a = (f >> 32) & 0xFFFFFFFF;
        }

        struct FaceVec3{
            int x, y, z;
        };
        static const FaceVec3 FACES_NORMALS[6];
        enum class FaceNormalType{
            X, Y, Z
        };
        static const FaceNormalType FACE_NORMAL_TYPES[6];

        void expand2DGrid(int z, FaceId f, const OutputFaces& inFaces, std::vector<FaceIntermediateWrapped>& wrapped, OutputFaces& outFaces);
        void expandFace(int& numFacesMerged, int aCoord, int bCoord, int gridSlice, int aSize, int bSize, FaceId f, FaceIntermediateContainer& fcc, const OutputFaces& faces, std::vector<FaceIntermediateWrapped>& wrapped, std::set<AV::uint64>& intermediateFaces);

        void commitFaces(OutputFaces& faces, std::set<AV::uint64>& intermediateFaces, FaceIntermediateContainer& fc, int gridSlice, FaceId f);

        int getDirectionAForNormalType(FaceNormalType ft) const;
        int getDirectionBForNormalType(FaceNormalType ft) const;

    };

};
