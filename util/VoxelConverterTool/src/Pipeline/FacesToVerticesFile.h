#pragma once

#include "Prerequisites.h"

#include <string>
#include <fstream>






//TODO clean this up
enum MeshChunkID {
    M_HEADER                = 0x1000,
        // char*          version           : Version number check
    M_MESH                = 0x3000,
        // Optional hash data for caches
        M_HASH_FOR_CACHES = 0x3200,

        // bool skeletallyAnimated   // --removed in 2.1 (flag was never used!)
        // unsigned char numPasses. // Number of caster passes data. Must be 1 or 2.
        // string strategyName;
        M_SUBMESH             = 0x4000,
            // char* materialName
            // uint8 blendIndexToBoneIndexCount
            // uint16 *blendIndexToBoneIndexTable
            // uint8 numLodLevels
            // Optional chunk that matches a texture name to an alias
            // a texture alias is sent to the submesh material to use this texture name
            // instead of the one in the texture unit with a matching alias name
            M_SUBMESH_TEXTURE_ALIAS = 0x4200, // Repeating section
                // char* aliasName;
                // char* textureName;
            M_SUBMESH_LOD       = 0x4300,
                // uint8 lodLevel
                // uint8 lodSource  //When lodLevel != lodSource; the M_SUBMESH_M_GEOMETRY* IDs aren't present.
                M_SUBMESH_LOD_OPERATION = 0x4310, // optional, trilist assumed if missing
                    // unsigned short operationType
                M_SUBMESH_INDEX_BUFFFER = 0x4320,
                    // unsigned int indexCount
                    // bool indexes32Bit (only if indexCount > 0)
                    // unsigned int* faceVertexIndices (indexCount)
                    // OR
                    // unsigned short* faceVertexIndices (indexCount)
                M_SUBMESH_M_GEOMETRY = 0x4330,
                    // unsigned int vertexCount
                    // uint8 numSources;    //Number of vertex buffers.
                    M_SUBMESH_M_GEOMETRY_VERTEX_DECLARATION = 0x4331,
                            // (this section repeats numSources times; the header isn't repeated)
                            // uint8 numVertexElements; // Number of elements in the declaration in this source.
                            // uint8 type;              // VertexElementType (repeating numVertexElements times)
                            // uint8 semantic;          // VertexElementSemantic (repeating numVertexElements times)
                    M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER = 0x4332, // Repeating section
                        // uint8 bindIndex;    // Index to bind this buffer to
                        // uint8 vertexSize;   // Per-vertex size, must agree with declaration at this index
                        // raw buffer data
                M_SUBMESH_M_GEOMETRY_EXTERNAL_SOURCE = 0x4340,
                    // This section is mutually exclusive w/ M_SUBMESH_M_GEOMETRY
                    // uint8 lodSource; //Get this vertex buffer from a LOD different source.
        M_MESH_SKELETON_LINK = 0x6000,
            // Optional link to skeleton
            // char* skeletonName           : name of .skeleton to use
        M_MESH_BOUNDS = 0x9000,
            // float centerX, centerY, centerZ
            // float halfSizeX, halfSizeY, halfSizeZ
            // float radius

        // Added By DrEvil
        // optional chunk that contains a table of submesh indexes and the names of
        // the sub-meshes.
        M_SUBMESH_NAME_TABLE = 0xA000,
            // Subchunks of the name table. Each chunk contains an index & string
            M_SUBMESH_NAME_TABLE_ELEMENT = 0xA100,
                // short index
                // char* name

        // Optional chunk which stores precomputed edge data
        M_EDGE_LISTS = 0xB000,
            // Each LOD has a separate edge list
            M_EDGE_LIST_LOD = 0xB100,
                // unsigned short lodIndex
                // bool isManual            // If manual, no edge data here, loaded from manual mesh
                    // bool isClosed
                    // unsigned long numTriangles
                    // unsigned long numEdgeGroups
                    // Triangle* triangleList
                        // unsigned long indexSet
                        // unsigned long vertexSet
                        // unsigned long vertIndex[3]
                        // unsigned long sharedVertIndex[3]
                        // float normal[4]

                    M_EDGE_GROUP = 0xB110,
                        // unsigned long vertexSet
                        // unsigned long triStart
                        // unsigned long triCount
                        // unsigned long numEdges
                        // Edge* edgeList
                            // unsigned long  triIndex[2]
                            // unsigned long  vertIndex[2]
                            // unsigned long  sharedVertIndex[2]
                            // bool degenerate

        // Optional poses section, referred to by pose keyframes
        M_POSES = 0xC000,
            M_POSE = 0xC100,
                // char* name (may be blank)
                // unsigned short target    // 0 for shared geometry,
                                            // 1+ for submesh index + 1
                // bool includesNormals [1.8+]
                M_POSE_VERTEX = 0xC111,
                    // unsigned long vertexIndex
                    // float xoffset, yoffset, zoffset
                    // float xnormal, ynormal, znormal (optional, 1.8+)
        // Optional vertex animation chunk
        M_ANIMATIONS = 0xD000,
            M_ANIMATION = 0xD100,
            // char* name
            // float length
            M_ANIMATION_BASEINFO = 0xD105,
            // [Optional] base keyframe information (pose animation only)
            // char* baseAnimationName (blank for self)
            // float baseKeyFrameTime

            M_ANIMATION_TRACK = 0xD110,
                // unsigned short type          // 1 == morph, 2 == pose
                // unsigned short target        // 0 for shared geometry,
                                                // 1+ for submesh index + 1
                M_ANIMATION_MORPH_KEYFRAME = 0xD111,
                    // float time
                    // bool includesNormals [1.8+]
                    // float x,y,z          // repeat by number of vertices in original geometry
                M_ANIMATION_POSE_KEYFRAME = 0xD112,
                    // float time
                    M_ANIMATION_POSE_REF = 0xD113, // repeat for number of referenced poses
                        // unsigned short poseIndex
                        // float influence

/* Version 1.10 of the .mesh format (deprecated)
enum MeshChunkID {
    M_HEADER                = 0x1000,
        // char*          version           : Version number check
    M_MESH                = 0x3000,
        // bool skeletallyAnimated   // important flag which affects h/w buffer policies
        // Optional M_GEOMETRY chunk
        M_SUBMESH             = 0x4000,
            // char* materialName
            // bool useSharedVertices
            // unsigned int indexCount
            // bool indexes32Bit
            // unsigned int* faceVertexIndices (indexCount)
            // OR
            // unsigned short* faceVertexIndices (indexCount)
            // M_GEOMETRY chunk (Optional: present only if useSharedVertices = false)
            */
            M_SUBMESH_OPERATION = 0x4010, // optional, trilist assumed if missing
                // unsigned short operationType
            M_SUBMESH_BONE_ASSIGNMENT = 0x4100,
                // Optional bone weights (repeating section)
                // unsigned int vertexIndex;
                // unsigned short boneIndex;
                // float weight;
            /*
            // Optional chunk that matches a texture name to an alias
            // a texture alias is sent to the submesh material to use this texture name
            // instead of the one in the texture unit with a matching alias name
            M_SUBMESH_TEXTURE_ALIAS = 0x4200, // Repeating section
                // char* aliasName;
                // char* textureName;*/

        M_GEOMETRY          = 0x5000, // NB this chunk is embedded within M_MESH and M_SUBMESH
            // unsigned int vertexCount
            M_GEOMETRY_VERTEX_DECLARATION = 0x5100,
                M_GEOMETRY_VERTEX_ELEMENT = 0x5110, // Repeating section
                    // unsigned short source;   // buffer bind source
                    // unsigned short type;     // VertexElementType
                    // unsigned short semantic; // VertexElementSemantic
                    // unsigned short offset;   // start offset in buffer in bytes
                    // unsigned short index;    // index of the semantic (for colours and texture coords)
            M_GEOMETRY_VERTEX_BUFFER = 0x5200, // Repeating section
                // unsigned short bindIndex;    // Index to bind this buffer to
                // unsigned short vertexSize;   // Per-vertex size, must agree with declaration at this index
                M_GEOMETRY_VERTEX_BUFFER_DATA = 0x5210,
                    // raw buffer data
        /*M_MESH_SKELETON_LINK = 0x6000,
            // Optional link to skeleton
            // char* skeletonName           : name of .skeleton to use
        */
        M_MESH_BONE_ASSIGNMENT = 0x7000,
            // Optional bone weights (repeating section)
            // unsigned int vertexIndex;
            // unsigned short boneIndex;
            // float weight;
        M_MESH_LOD_LEVEL = 0x8000,
            // Optional LOD information
            // string strategyName;
            // unsigned short numLevels;
            // bool manual;  (true for manual alternate meshes, false for generated)
            M_MESH_LOD_USAGE = 0x8100,
            // Repeating section, ordered in increasing depth
            // NB LOD 0 (full detail from 0 depth) is omitted
            // LOD value - this is a distance, a pixel count etc, based on strategy
            // float lodValue;
                M_MESH_LOD_MANUAL = 0x8110,
                // Required if M_MESH_LOD section manual = true
                // String manualMeshName;
                M_MESH_LOD_GENERATED = 0x8120,
                // Required if M_MESH_LOD section manual = false
                // Repeating section (1 per submesh)
                // unsigned int indexCount;
                // bool indexes32Bit
                // unsigned short* faceIndexes;  (indexCount)
                // OR
                // unsigned int* faceIndexes;  (indexCount)
        /*M_MESH_BOUNDS = 0x9000,
            // float minx, miny, minz
            // float maxx, maxy, maxz
            // float radius

        // Added By DrEvil
        // optional chunk that contains a table of submesh indexes and the names of
        // the sub-meshes.
        M_SUBMESH_NAME_TABLE = 0xA000,
            // Subchunks of the name table. Each chunk contains an index & string
            M_SUBMESH_NAME_TABLE_ELEMENT = 0xA100,
                // short index
                // char* name

        // Optional chunk which stores precomputed edge data
        M_EDGE_LISTS = 0xB000,
            // Each LOD has a separate edge list
            M_EDGE_LIST_LOD = 0xB100,
                // unsigned short lodIndex
                // bool isManual            // If manual, no edge data here, loaded from manual mesh
                    // bool isClosed
                    // unsigned long numTriangles
                    // unsigned long numEdgeGroups
                    // Triangle* triangleList
                        // unsigned long indexSet
                        // unsigned long vertexSet
                        // unsigned long vertIndex[3]
                        // unsigned long sharedVertIndex[3]
                        // float normal[4]

                    M_EDGE_GROUP = 0xB110,
                        // unsigned long vertexSet
                        // unsigned long triStart
                        // unsigned long triCount
                        // unsigned long numEdges
                        // Edge* edgeList
                            // unsigned long  triIndex[2]
                            // unsigned long  vertIndex[2]
                            // unsigned long  sharedVertIndex[2]
                            // bool degenerate

        // Optional poses section, referred to by pose keyframes
        M_POSES = 0xC000,
            M_POSE = 0xC100,
                // char* name (may be blank)
                // unsigned short target    // 0 for shared geometry,
                                            // 1+ for submesh index + 1
                // bool includesNormals [1.8+]
                M_POSE_VERTEX = 0xC111,
                    // unsigned long vertexIndex
                    // float xoffset, yoffset, zoffset
                    // float xnormal, ynormal, znormal (optional, 1.8+)
        // Optional vertex animation chunk
        M_ANIMATIONS = 0xD000,
            M_ANIMATION = 0xD100,
            // char* name
            // float length
            M_ANIMATION_BASEINFO = 0xD105,
            // [Optional] base keyframe information (pose animation only)
            // char* baseAnimationName (blank for self)
            // float baseKeyFrameTime

            M_ANIMATION_TRACK = 0xD110,
                // unsigned short type          // 1 == morph, 2 == pose
                // unsigned short target        // 0 for shared geometry,
                                                // 1+ for submesh index + 1
                M_ANIMATION_MORPH_KEYFRAME = 0xD111,
                    // float time
                    // bool includesNormals [1.8+]
                    // float x,y,z          // repeat by number of vertices in original geometry
                M_ANIMATION_POSE_KEYFRAME = 0xD112,
                    // float time
                    M_ANIMATION_POSE_REF = 0xD113, // repeat for number of referenced poses
                        // unsigned short poseIndex
                        // float influence

        // Optional submesh extreme vertex list chink
        */
        M_TABLE_EXTREMES = 0xE000,
        // unsigned short submesh_index;
        // float extremes [n_extremes][3];

};

namespace VoxelConverterTool{

    struct OutputFaces;


    static const uint32 FACES_VERTICES[] = {
        0, 1, 2, 3,
        5, 4, 7, 6,
        0, 4, 5, 1,
        2, 6, 7, 3,
        1, 5, 6, 2,
        0, 3, 7, 4
    };
    static const uint32 VERTICES_POSITIONS[] = {
        0, 0, 0,
        1, 0, 0,
        1, 0, 1,
        0, 0, 1,
        0, 1, 0,
        1, 1, 0,
        1, 1, 1,
        0, 1, 1
    };

    class FacesToVerticesFile{
    public:
        FacesToVerticesFile();
        ~FacesToVerticesFile();

        void writeToFile(const std::string& filePath, const OutputFaces& outFaces);

    private:
        void writeShorts(const uint16* const pShort, size_t count = 1);
        void writeFloats(const float* const pFloat, size_t count);
        void writeChunkHeader(uint16 id, size_t size);
        void writeFileHeader(void);
        void writeString(const std::string& string);
        void writeData(const void* const buf, size_t size, size_t count);
        void writeInts(const uint32* const pInt, size_t count);

        void writeMesh(const OutputFaces& outFaces);

        bool mFlipEndian = false;
        std::ofstream* mStream;
    };

};
