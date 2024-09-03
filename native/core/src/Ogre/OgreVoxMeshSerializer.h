#pragma once

#include "OgreMesh2.h"
#include "OgreSerializer.h"
#include "Vao/OgreVertexBufferPacked.h"

namespace Ogre{

    class VoxMeshSerializer : public Serializer{
    public:

        VoxMeshSerializer( VaoManager *vaoManager );
        ~VoxMeshSerializer();

        void importMesh(DataStreamPtr& stream, Mesh* pMesh);

    private:
        VaoManager *mVaoManager;

        void readMesh(DataStreamPtr& stream, Mesh* pMesh);
        void readSubMesh(DataStreamPtr& stream, Mesh* pMesh, uint8 numVaoPasses);

        uint8* readVertexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outVerts);
        uint8* readIndexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outIndices);

        typedef vector<uint8*>::type Uint8Vec;
        struct SubMeshLod
        {
            uint32                  numVertices;
            VertexElement2VecVec    vertexDeclarations;
            Uint8Vec                vertexBuffers;
            uint8                   lodSource;
            bool                    index32Bit;
            uint32                  numIndices;
            void                    *indexData;
            OperationType operationType;

            SubMeshLod();
        };
        typedef vector<SubMeshLod>::type SubMeshLodVec;

        void readSubMeshLod( DataStreamPtr& stream, Mesh *pMesh, SubMeshLod *subLod, uint8 currentLod );

        void readIndexes(DataStreamPtr& stream, SubMeshLod *subLod);

        void readGeometry(DataStreamPtr& stream, SubMeshLod *subLod);

        void readVertexDeclaration(DataStreamPtr& stream, SubMeshLod *subLod);

        void readVertexBuffer(DataStreamPtr& stream, SubMeshLod *subLod);



        void flipLittleEndian( void* pData, VertexBufferPacked *vertexBuffer );
        void flipLittleEndian( void* pData, size_t numVertices, size_t bytesPerVertex, const VertexElement2Vec &vertexElements );
        void flipEndian( void* pData, size_t vertexCount, size_t vertexSize, size_t baseOffset, const VertexElementType elementType );
        void readSubMeshLodOperation( DataStreamPtr& stream, SubMeshLod *subLod );
        void createSubMeshVao( SubMesh *sm, SubMeshLodVec &submeshLods, uint8 casterPass );



    };

}
