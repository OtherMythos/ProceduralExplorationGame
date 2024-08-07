#pragma once

#include <string>
#include "GamePrerequisites.h"
#include "OgrePrerequisites.h"

namespace ProceduralExplorationGameCore{

    static const AV::uint32 NUM_VERTS = 6;
    static const AV::uint32 COLS_WIDTH = 16;
    static const AV::uint32 COLS_HEIGHT = 16;
    static const float TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0;
    static const float TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0;

    static const float MASKS[] = {
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

    static const char VERTICE_BORDERS[] = {
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

        void* mVerts = 0;
        AV::uint32* mVertsWritePtr = 0;
    };

    class Voxeliser{
    public:
        Voxeliser();
        ~Voxeliser();

        void createTerrainFromMapData(const std::string& meshName, ExplorationMapData* mapData, Ogre::MeshPtr* outMeshes, AV::uint32* outNumRegions);

    private:
        void prepareVertBuffer();

        inline AV::uint32 getVerticeBorderTerrain(AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 f, AV::uint32 x, AV::uint32 y, AV::uint32 width) const;
        inline void writeFaceToMesh(AV::uint32 targetX, AV::uint32 targetY, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 width, AV::uint32 height, float texCoordX, float texCoordY, RegionBufferEntry& bufEntry) const;
    };

};
