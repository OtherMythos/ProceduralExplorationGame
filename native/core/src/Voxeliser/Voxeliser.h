#pragma once

#include <string>
#include "GamePrerequisites.h"
#include "VisitedPlaces/VisitedPlacesPrerequisites.h"
#include "TerrainFaceMerger.h"
#include "OgrePrerequisites.h"

namespace ProceduralExplorationGameCore{

    static const AV::uint32 NUM_VERTS = 6;
    static const AV::uint32 COLS_WIDTH = 16;
    static const AV::uint32 COLS_HEIGHT = 16;
    static const float TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0;
    static const float TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0;

    static const AV::uint32 TERRAIN_MAGIC_NUMBER = 0x15FBF7DB;
    static const AV::uint32 VOXELISER_MAGIC_NUMBER = 0x15FBF7FB;

    static const int MASKS[] = {
        0, -1, 0,
        0, 1, 0,
        0, 0, -1,
        0, 0, 1,
        1, 0, 0,
        -1, 0, 0,
    };
    static const AV::uint32 FACES_VERTICES[] = {
        0, 1, 2, 3,
        5, 4, 7, 6,
        0, 4, 5, 1,
        2, 6, 7, 3,
        1, 5, 6, 2,
        0, 3, 7, 4
    };
    static const AV::uint32 VERTICES_POSITIONS[] = {
        0, 0, 0,
        1, 0, 0,
        1, 0, 1,
        0, 0, 1,
        0, 1, 0,
        1, 1, 0,
        1, 1, 1,
        0, 1, 1
    };
    static const float FACES_NORMALS[] = {
        0, -1,  0,
        0,  1,  0,
        0,  0, -1,
        0,  0,  1,
        1,  0,  0,
        -1,  0,  0,
    };

    static const int8_t VERTICE_BORDERS[] = {
        //F0
        -1, -1,  0, /**/ 0, -1, -1, /**/ -1, -1, -1,
         0, -1, -1, /**/ 1, -1,  0, /**/  1, -1, -1,
         1, -1,  0, /**/ 0, -1,  1, /**/  1, -1,  1,
         0, -1,  1, /**/-1, -1,  0, /**/ -1, -1,  1,
        //F1
         1,  1,  0, /**/  0,  1, -1, /**/ 1,  1, -1,
         0,  1, -1, /**/ -1,  1,  0, /**/-1,  1, -1,
        -1,  1,  0, /**/  0,  1,  1, /**/-1,  1,  1,
         0,  1,  1, /**/  1,  1,  0, /**/ 1,  1,  1,
        //F2
         0, -1, -1, /**/ -1,  0, -1, /**/-1, -1, -1,
        -1,  0, -1, /**/  0,  1, -1, /**/-1,  1, -1,
         0,  1, -1, /**/  1,  0, -1, /**/ 1,  1, -1,
         1,  0, -1, /**/  0, -1, -1, /**/ 1, -1, -1,
        //F3
         0, -1,  1, /**/  1,  0,  1, /**/ 1, -1,  1,
         1,  0,  1, /**/  0,  1,  1, /**/ 1,  1,  1,
         0,  1,  1, /**/ -1,  0,  1, /**/-1,  1,  1,
        -1,  0,  1, /**/  0, -1,  1, /**/-1, -1,  1,
        //F4
        1, -1,  0, /**/ 1,  0, -1, /**/ 1, -1, -1,
        1,  0, -1, /**/ 1,  1,  0, /**/ 1,  1, -1,
        1,  1,  0, /**/ 1,  0,  1, /**/ 1,  1,  1,
        1,  0,  1, /**/ 1, -1,  0, /**/ 1, -1,  1,
        //F5
        -1,  0, -1, /**/ -1, -1,  0, /**/ -1, -1, -1,
        -1, -1,  0, /**/ -1,  0,  1, /**/ -1, -1,  1,
        -1,  0,  1, /**/ -1,  1,  0, /**/ -1,  1,  1,
        -1,  1,  0, /**/ -1,  0, -1, /**/ -1,  1, -1,
    };

    class RegionBufferEntry{
    public:

        void prepareVertBuffer();
        Ogre::MeshPtr generateMesh(const std::string& meshName, AV::uint32 width, AV::uint32 height, int maxAltitude);

        size_t mNumActiveVox = 0;
        RegionId mId = 0;

        size_t mNumVerts = 0;
        size_t mNumTris = 0;

        AV::uint32 mMinX, mMinY, mMaxX, mMaxY;

        void* mVerts = 0;
        AV::uint32* mVertsWritePtr = 0;
    };

    class Voxeliser{
    public:
        Voxeliser();
        ~Voxeliser();

        void createTerrainFromMapData(const std::string& meshName, ExplorationMapData* mapData, Ogre::MeshPtr* outMeshes, AV::uint32* outNumRegions);

        void createMeshForVoxelData(const std::string& meshName, VoxelId* data, AV::uint32 width, AV::uint32 height, AV::uint32 depth, Ogre::MeshPtr* outMesh);

        void createTerrainFromVisitedPlaceMapData(const std::string& meshName, VisitedPlaceMapData* mapData, Ogre::MeshPtr* outMeshes, AV::uint32 x, AV::uint32 y, AV::uint32 width, AV::uint32 height);
        void createTerrainFromVisitedPlaceMapDataAlteredValues(const std::string& meshName, VisitedPlaceMapData* mapData, Ogre::MeshPtr* outMesh, AV::uint32 xVal, AV::uint32 yVal, AV::uint32 widthVal, AV::uint32 heightVal);





        // Define structures for the algorithm
        struct TerrainFace {
            AV::uint32 x, y, z;
            AV::uint32 direction;
            AV::uint8 voxelType;
            AV::uint8 ambientMask;
        };

        struct MergedFace {
            AV::uint32 x, y, z;
            AV::uint32 width, height;
            AV::uint32 direction;
            AV::uint8 voxelType;
            AV::uint8 ambientMask;
        };
        size_t calculateFaceIndex(AV::uint32 faceDir, AV::uint32 x, AV::uint32 y, AV::uint32 z,
                                            AV::uint32 width, AV::uint32 height) const;
        AV::uint64 getFaceKey(AV::uint32 x, AV::uint32 y, AV::uint32 z) const;
        void writeMergedFacesToBuffer(const std::vector<MergedFace>& mergedFaces, RegionBufferEntry& bufEntry);
        void setupFaceCorners(const MergedFace& face, AV::uint32 corners[4][3]) const;
        void mergeTerrainFaces(RegionBufferEntry& bufEntry);



    private:
        void prepareVertBuffer();

        inline AmbientMask getVerticeBorderTerrain(AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 f, AV::uint32 x, AV::uint32 y, AV::uint32 width) const;
        inline void writeFaceToMesh(AV::uint32 targetX, AV::uint32 targetY, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 width, AV::uint32 height, AV::uint8 v, RegionBufferEntry& bufEntry) const;
        inline void writeFaceToMeshVisitedPlace(int targetX, int targetY, AV::uint32 xVal, AV::uint32 yVal, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint8 altitude, const std::vector<AV::uint8>& altitudes, AV::uint32 width, AV::uint32 height, AV::uint8 v, AV::uint32 totalWidth, AV::uint32 totalHeight, RegionBufferEntry& bufEntry) const;

        AV::uint8 getNeighbourMask(VoxelId* data, int x, int y, int z, AV::uint32 width, AV::uint32 height, AV::uint32 depth);
        AV::uint32 getVerticeBorder(VoxelId* data, AV::uint8 f, int x, int y, int z, AV::uint32 width, AV::uint32 height, AV::uint32 depth);

        AV::uint32 getVerticeBorderTerrainVisitedPlaces(AV::uint32 altitude, const std::vector<AV::uint8>& altitudes, AV::uint32 f, int x, int y, AV::uint32 width, AV::uint32 height) const;

        VoxelId readVoxelFromData_(VoxelId* data, int x, int y, int z, AV::uint32 width, AV::uint32 height);
    };

};
