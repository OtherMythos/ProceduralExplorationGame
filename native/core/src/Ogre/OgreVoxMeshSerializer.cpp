#include "OgreVoxMeshSerializer.h"

#include "Ogre.h"
#include "OgreMeshFileFormat.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"
#include "OgreBitwise.h"

#include <iostream>

namespace Ogre{

    VoxMeshSerializer::VoxMeshSerializer( VaoManager *vaoManager )
        : mVaoManager(vaoManager)
    {
        mVersion = "[VoxMeshSerializer_v0.6.0]";
    }

    VoxMeshSerializer::~VoxMeshSerializer(){

    }

    template <typename T>
    void _writeIndiceValues(uint8* startPtr, size_t numFaces){
        T current = 0;
        T* writePtr = reinterpret_cast<T*>(startPtr);
        for(uint32 i = 0; i < numFaces; i++){
            *writePtr++ = (current + 0);
            *writePtr++ = (current + 1);
            *writePtr++ = (current + 2);
            *writePtr++ = (current + 2);
            *writePtr++ = (current + 3);
            *writePtr++ = (current + 0);
            current += 4;
        }
    }

    void VoxMeshSerializer::importMesh(DataStreamPtr& stream, Mesh* pMesh){
        stream->seek(0);

        determineEndianness(stream);
        try{

            readFileHeader(stream);
        }catch(Ogre::Exception e){

        }

        uint8* vertexData = 0;
        uint8* indiceData = 0;
        size_t numVerts = 0;
        size_t numIndices = 0;
        Ogre::Aabb foundAABB;
        float foundRadius;
        {
            pushInnerChunk(stream);
            uint16 streamID = readChunk(stream);
            if(streamID != M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER){
                OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                    "Expected vertex definition for mesh " + pMesh->getName(),
                    "VoxMeshSerializer::importMesh" );
            }
            vertexData = readVertexBuffer(stream, pMesh, &numVerts);
            popInnerChunk(stream);
        }
        {
            pushInnerChunk(stream);
            uint16 streamID = readChunk(stream);
            if(streamID != M_MESH_BOUNDS){
                OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                    "Expected bounds definition for mesh " + pMesh->getName(),
                    "VoxMeshSerializer::importMesh" );
            }
            readBoundsInfo(stream, foundAABB, foundRadius);
            popInnerChunk(stream);
        }

        Ogre::VertexBufferPacked *vertexBuffer = 0;
        Ogre::RenderSystem *renderSystem = Ogre::Root::getSingletonPtr()->getRenderSystem();
        Ogre::VaoManager *vaoManager = renderSystem->getVaoManager();
        static const Ogre::VertexElement2Vec elemVec = {
            Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_POSITION),
            Ogre::VertexElement2(Ogre::VET_FLOAT1, Ogre::VES_NORMAL),
            Ogre::VertexElement2(Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES),
        };
        try{
            //TODO should keep as shadow buffer be true?
            vertexBuffer = vaoManager->createVertexBuffer(elemVec, numVerts, Ogre::BT_DEFAULT, vertexData, true);
        }catch(Ogre::Exception &e){
            vertexBuffer = 0;
        }

        //Generate the indices in code.
        size_t numFaces = numVerts / 4;
        size_t numBytesPerIndice = sizeof(uint16);
        if(numFaces * 4 >= 0xFFFF){
            numBytesPerIndice = sizeof(uint32);
        }
        size_t indiceBufferSize = numFaces * 6 * numBytesPerIndice;

        size_t bytesPerFace = numBytesPerIndice * 6;
        indiceData = reinterpret_cast<uint8*>( OGRE_MALLOC_SIMD(
                                //sizeof(uint8) * bytesPerFace * numFaces,
                                indiceBufferSize,
                                MEMCATEGORY_GEOMETRY ) );


        Ogre::IndexType indexType = Ogre::IndexType::IT_32BIT;
        if(numBytesPerIndice == sizeof(uint32)){
            _writeIndiceValues<uint32>(indiceData, numFaces);
            indexType = Ogre::IndexType::IT_32BIT;
        }else{
            _writeIndiceValues<uint16>(indiceData, numFaces);
            indexType = Ogre::IndexType::IT_16BIT;
        }
        numIndices = numFaces * 6;

        Ogre::IndexBufferPacked* indexBuffer = vaoManager->createIndexBuffer(indexType, numIndices, Ogre::BT_IMMUTABLE, indiceData, false);

        Ogre::VertexBufferPackedVec vertexBuffers;
        vertexBuffers.push_back(vertexBuffer);
        Ogre::VertexArrayObject* arrayObj = vaoManager->createVertexArrayObject(vertexBuffers, indexBuffer, Ogre::OT_TRIANGLE_LIST);

        Ogre::SubMesh* subMesh = pMesh->createSubMesh();

        subMesh->mVao[Ogre::VpNormal].push_back(arrayObj);
        subMesh->mVao[Ogre::VpShadow].push_back(arrayObj);

        pMesh->_setBounds(foundAABB);
        pMesh->_setBoundingSphereRadius(foundRadius);

        subMesh->setMaterialName("baseVoxelMaterial");

        stream->seek(0);
    }

    uint8* VoxMeshSerializer::readVertexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outNumVerts){
        size_t bytesPerVertex = sizeof(unsigned int) * 6;
        size_t numVertices = mCurrentstreamLen / bytesPerVertex;
        uint8 *vertexData = reinterpret_cast<uint8*>( OGRE_MALLOC_SIMD(
                                sizeof(uint8) * bytesPerVertex * numVertices,
                                MEMCATEGORY_GEOMETRY ) );

        stream->read(vertexData, sizeof(uint8) * bytesPerVertex * numVertices);

        *outNumVerts = numVertices;

        return vertexData;

    }

    void VoxMeshSerializer::readBoundsInfo(DataStreamPtr& stream, Ogre::Aabb& outAABB, float& outRadius){
        Vector3 centre, halfSize;
        // float centreX, centreY, centreZ
        readFloats(stream, &centre.x, 1);
        readFloats(stream, &centre.y, 1);
        readFloats(stream, &centre.z, 1);
        // float halfSizeX, halfSizeY, halfSizeZ
        readFloats(stream, &halfSize.x, 1);
        readFloats(stream, &halfSize.y, 1);
        readFloats(stream, &halfSize.z, 1);
        outAABB.mCenter = centre;
        outAABB.mHalfSize = halfSize;

        readFloats(stream, &outRadius, 1);
    }

}
