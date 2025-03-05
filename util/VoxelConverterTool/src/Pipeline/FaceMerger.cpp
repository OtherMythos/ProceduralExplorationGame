#include "FaceMerger.h"

#include <cassert>
#include <set>

namespace VoxelConverterTool{

    const FaceMerger::FaceIntermediateWrapped FaceMerger::INVALID_FACE_INTERMEDIATE = 0xFFFF;

    const FaceMerger::FaceVec3 FaceMerger::FACES_NORMALS[6] = {
        {0, -1,  0},
        {0,  1,  0},
        {0,  0, -1},
        {0,  0,  1},
        {1,  0,  0},
        {-1, 0,  0},
    };

    const FaceMerger::FaceNormalType FaceMerger::FACE_NORMAL_TYPES[6] = {
        FaceMerger::FaceNormalType::Y,
        FaceMerger::FaceNormalType::Y,
        FaceMerger::FaceNormalType::Z,
        FaceMerger::FaceNormalType::Z,
        FaceMerger::FaceNormalType::X,
        FaceMerger::FaceNormalType::X,
    };

    FaceMerger::FaceMerger(){

    }

    FaceMerger::~FaceMerger(){

    }

    int FaceMerger::getDirectionAForNormalType(FaceNormalType ft) const{
        if(ft == FaceNormalType::Z){
            return 1;
        }
        return FACES_NORMALS[static_cast<size_t>(ft)].x;
    }

    int FaceMerger::getDirectionBForNormalType(FaceNormalType ft) const{
        return FACES_NORMALS[static_cast<size_t>(ft)].y;
    }

    void FaceMerger::commitFaces(VoxelConverterTool::OutputFaces& faces, std::set<uint64>& intermediateFaces, FaceIntermediateContainer& fc, int gridSlice, FaceId f){
        int minA = -1;
        int minB = -1;
        int maxA = -1;
        int maxB = -1;
        for(uint64 f : intermediateFaces){
            int aCoord = static_cast<int>(f & 0xFFFF);
            int bCoord = static_cast<int>((f >> 32) & 0xFFFF);

            minA = aCoord;
            minB = bCoord;
            assert(aCoord >= 0);
            assert(bCoord >= 0);
        }

        WrappedFaceContainer container;
        container.vox = fc.v;
        container.ambientMask = fc.a;
        container.z = gridSlice;
        container.x = minA;
        container.y = minB;
        container.faceMask = f;
        FaceNormalType ft = FACE_NORMAL_TYPES[f];
        WrappedFace wf = _wrapFace(container);
        faces.outFaces.push_back(wf);
    }

    void FaceMerger::expandFace(int& numFacesMerged, int aCoord, int bCoord, int gridSlice, int aSize, int bSize, FaceId f, FaceIntermediateContainer& fcc, const VoxelConverterTool::OutputFaces& faces, std::vector<FaceIntermediateWrapped>& wrapped, std::set<uint64>& intermediateFaces){

        assert(aCoord >= 0);
        assert(bCoord >= 0);

        const int width = 256;
        const int height = 256;

        size_t idx = aCoord + (bCoord * width) + (gridSlice * width * height);
        FaceIntermediateWrapped fiw = wrapped[idx];
        if(fiw == INVALID_FACE_INTERMEDIATE) return;
        FaceIntermediateContainer fc;
        _unwrapFaceIntermediate(fiw, fc);

        if(numFacesMerged > 0){
            //If this is not the first face found, check if the face types match.
            if(fcc.a != fc.a || fcc.v != fc.v){
                return;
            }
        }

        _unwrapFaceIntermediate(fiw, fcc);

        FaceNormalType ft = FACE_NORMAL_TYPES[f];
        int dirA = getDirectionAForNormalType(ft);
        int dirB = getDirectionBForNormalType(ft);
        //Prevent infinite loops
        assert(dirA != 0 || dirB != 0);

        intermediateFaces.insert(static_cast<uint64>(aCoord) | static_cast<uint64>(bCoord) << 32);
        wrapped[idx] = INVALID_FACE_INTERMEDIATE;
        numFacesMerged++;

        return;
        expandFace(numFacesMerged, aCoord + dirA, bCoord + dirB, gridSlice, aSize, bSize, f, fc, faces, wrapped, intermediateFaces);

    }

    void FaceMerger::expand2DGrid(int z, FaceId f, const VoxelConverterTool::OutputFaces& inFaces, std::vector<FaceIntermediateWrapped>& wrapped, VoxelConverterTool::OutputFaces& outFaces){

        //const int width = inFaces.deltaX;
        //const int height = inFaces.deltaZ;
        const int width = 256;
        const int height = 256;

        std::set<uint64> foundFaces;
        for(int y = 0; y < height; y++){
            for(int x = 0; x < width; x++){
                FaceIntermediateContainer fc;
                int numFacesMerged = 0;
                expandFace(numFacesMerged, x, y, z, width, height, f, fc, inFaces, wrapped, foundFaces);
                if(!foundFaces.empty()){
                    commitFaces(outFaces, foundFaces, fc, z, f);
                    foundFaces.clear();
                }
            }
        }

    }

    VoxelConverterTool::OutputFaces FaceMerger::mergeFaces(const VoxelConverterTool::OutputFaces& faces){
        std::vector<FaceIntermediateWrapped> faceBuffer;
        //size_t bufSize = faces.deltaX * faces.deltaY * faces.deltaZ;
        size_t bufSize = 256 * 256 * 256;
        faceBuffer.resize(bufSize, INVALID_FACE_INTERMEDIATE);

        const int width = 256;
        const int height = 256;
        const int depth = 256;

        VoxelConverterTool::OutputFaces outFaces;

        for(FaceId f = 0; f < 6; f++){
            FaceNormalType ft = FACE_NORMAL_TYPES[f];

            //Produce an easily searchable data structure containing only the target faces.
            for(const WrappedFace wf : faces.outFaces){
                WrappedFaceContainer fc;
                _unwrapFace(wf, fc);

                int xx = fc.x;
                int yy = fc.y;
                int zz = fc.z;

                if(fc.faceMask != f) continue;
                FaceIntermediateContainer fic = {fc.vox, fc.ambientMask};
                FaceIntermediateWrapped fi =_wrapFaceIntermediate(fic);
                size_t idx = xx + (yy * width) + (zz * width * height);
                assert(idx < faceBuffer.size());
                faceBuffer[idx] = fi;
            }

            for(int z = 0; z < depth; z++){
                expand2DGrid(z, f, faces, faceBuffer, outFaces);
            }

            for(FaceIntermediateWrapped fiw : faceBuffer){
                assert(fiw == INVALID_FACE_INTERMEDIATE);
            }
        }

        outFaces.deltaX = faces.deltaX;
        outFaces.deltaY = faces.deltaY;
        outFaces.deltaZ = faces.deltaZ;

        outFaces.minX = faces.minX;
        outFaces.minY = faces.minY;
        outFaces.minZ = faces.minZ;

        outFaces.maxX = faces.maxX;
        outFaces.maxY = faces.maxY;
        outFaces.maxZ = faces.maxZ;

        return outFaces;
    }

}
