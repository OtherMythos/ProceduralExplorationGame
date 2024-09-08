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
        /*
        pushInnerChunk(stream);
        uint16 streamID;
        while(!stream->eof()){
            streamID = readChunk(stream);
            switch(streamID){
                case M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER:
                    //readMesh(stream, pMesh);
                    readVertexBuffer(stream, pMesh);
                    break;
            }
        }
        popInnerChunk(stream);
         */

        uint8* vertexData = 0;
        uint8* indiceData = 0;
        size_t numVerts = 0;
        size_t numIndices = 0;
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
        /*
        {
            pushInnerChunk(stream);
            uint16 streamID = readChunk(stream);
            if(streamID != M_SUBMESH_INDEX_BUFFFER){
                OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                    "Expected index buffer for mesh " + pMesh->getName(),
                    "VoxMeshSerializer::importMesh" );
            }
            //indiceData = readIndexBuffer(stream, pMesh, &numIndices);
            //readVertexBuffer(stream, pMesh);
            popInnerChunk(stream);
        }
        */

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

        //const Ogre::Vector3 halfBounds(width/2, height/2, depth/2);
        const Ogre::Vector3 halfBounds(10, 10, 10);
        const Ogre::Aabb bounds(halfBounds, halfBounds);
        pMesh->_setBounds(bounds);
        pMesh->_setBoundingSphereRadius(bounds.getRadius());

        subMesh->setMaterialName("baseVoxelMaterial");

        stream->seek(0);
    }

    uint8* VoxMeshSerializer::readIndexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outNumIndices){
        int bytesPerFace = sizeof(unsigned int) * 6;
        int numFaces = mCurrentstreamLen / bytesPerFace;
        uint8 *indiceData = reinterpret_cast<uint8*>( OGRE_MALLOC_SIMD(
                                sizeof(uint8) * bytesPerFace * numFaces,
                                MEMCATEGORY_GEOMETRY ) );

        stream->read(indiceData, sizeof(uint8) * bytesPerFace * numFaces);

        *outNumIndices = numFaces * 6;

        /*
        uint32 *p = reinterpret_cast<uint32*>(indiceData);
        for(int i = 0; i < 8; i++){
            std::cout << *p << std::endl;
            p++;
        }
        */

        return indiceData;
    }

    uint8* VoxMeshSerializer::readVertexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outNumVerts){
        size_t bytesPerVertex = sizeof(unsigned int) * 6;
        size_t numVertices = mCurrentstreamLen / bytesPerVertex;
        uint8 *vertexData = reinterpret_cast<uint8*>( OGRE_MALLOC_SIMD(
                                sizeof(uint8) * bytesPerVertex * numVertices,
                                MEMCATEGORY_GEOMETRY ) );

        stream->read(vertexData, sizeof(uint8) * bytesPerVertex * numVertices);

        *outNumVerts = numVertices;

        /*
        uint32 *p = reinterpret_cast<uint32*>(vertexData);
        for(int i = 0; i < 6; i++){
            std::cout << *p << std::endl;
            p++;
        }
        */

        return vertexData;


    }

    void VoxMeshSerializer::readMesh(DataStreamPtr& stream, Mesh* pMesh){
        // Read the strategy to be used for this mesh
        // string strategyName;
        pMesh->setLodStrategyName( readString( stream ) );

        uint8 numVaoPasses = 1;
        readChar( stream, &numVaoPasses );
        assert( numVaoPasses == 1 || numVaoPasses == 2 );

        // Find all substreams
        if (!stream->eof())
        {
            pushInnerChunk(stream);
            uint16 streamID = readChunk(stream);
            while(!stream->eof() &&
                  (streamID == M_SUBMESH ||
                   streamID == M_MESH_SKELETON_LINK ||
                   streamID == M_MESH_BOUNDS ||
                   streamID == M_SUBMESH_NAME_TABLE ||
                   streamID == M_MESH_LOD_LEVEL ||
                   streamID == M_HASH_FOR_CACHES /*||
                                                  streamID == M_EDGE_LISTS ||
                                                  streamID == M_POSES ||
                                                  streamID == M_ANIMATIONS*/))
            {
                switch(streamID)
                {
                    case M_SUBMESH:
                        readSubMesh(stream, pMesh, numVaoPasses);
                        break;
                    case M_MESH_SKELETON_LINK:
                        //readSkeletonLink(stream, pMesh, listener);
                        break;
                    case M_MESH_LOD_LEVEL:
                        //readMeshLodLevel(stream, pMesh);
                        break;
                    case M_MESH_BOUNDS:
                        //readBoundsInfo(stream, pMesh);
                        break;
                    case M_SUBMESH_NAME_TABLE:
                        //readSubMeshNameTable(stream, pMesh);
                        break;
                    case M_HASH_FOR_CACHES:
                        //readHashForCaches(stream, pMesh);
                        break;
                    }

                if (!stream->eof())
                {
                    streamID = readChunk(stream);
                }

            }
            if (!stream->eof())
            {
                // Backpedal back to start of stream
                backpedalChunkHeader(stream);
            }
            popInnerChunk(stream);
        }
    }

    void VoxMeshSerializer::readSubMesh(DataStreamPtr& stream, Mesh* pMesh, uint8 numVaoPasses){
        SubMesh* sm = pMesh->createSubMesh();

        // char* materialName
        String materialName = readString(stream);
        sm->setMaterialName( materialName );

        uint8 blendIndexToBoneIndexCount = 0;
        readChar( stream, &blendIndexToBoneIndexCount );
        if( blendIndexToBoneIndexCount )
        {
            sm->mBlendIndexToBoneIndexMap.resize( blendIndexToBoneIndexCount );
            readShorts( stream, sm->mBlendIndexToBoneIndexMap.begin(), blendIndexToBoneIndexCount );
        }

        uint8 numLodLevels = 0;
        readChar( stream, &numLodLevels );

        SubMeshLodVec totalSubmeshLods;
        totalSubmeshLods.reserve( numLodLevels * numVaoPasses );

        //M_SUBMESH_LOD
        pushInnerChunk(stream);
        try
        {
            SubMeshLodVec submeshLods;
            submeshLods.reserve( numLodLevels );

            for( uint8 i=0; i<numVaoPasses; ++i )
            {
                for( uint8 j=0; j<numLodLevels; ++j )
                {
                    uint16 streamID = readChunk(stream);
                    assert( streamID == M_SUBMESH_LOD && !stream->eof() );

                    totalSubmeshLods.push_back( SubMeshLod() );
                    const uint8 currentLod = static_cast<uint8>( submeshLods.size() );
                    readSubMeshLod( stream, pMesh, &totalSubmeshLods.back(), currentLod );

                    submeshLods.push_back( totalSubmeshLods.back() );
                }

                createSubMeshVao( sm, submeshLods, i );
                submeshLods.clear();
            }

            //Populate mBoneAssignments and mBlendIndexToBoneIndexMap;
            size_t indexSource = 0;
            size_t unusedVar = 0;

            const VertexElement2 *indexElement =
                    sm->mVao[VpNormal][0]->findBySemantic( VES_BLEND_INDICES, indexSource, unusedVar );
            if( indexElement )
            {
                const uint8 *vertexData = totalSubmeshLods[0].vertexBuffers[indexSource];
                sm->_buildBoneAssignmentsFromVertexData( vertexData );
            }
        }
        catch( Exception& )
        {
            SubMeshLodVec::iterator itor = totalSubmeshLods.begin();
            SubMeshLodVec::iterator end  = totalSubmeshLods.end();

            while( itor != end )
            {
                Uint8Vec::iterator it = itor->vertexBuffers.begin();
                Uint8Vec::iterator en = itor->vertexBuffers.end();

                while( it != en )
                    OGRE_FREE_SIMD( *it++, MEMCATEGORY_GEOMETRY );

                itor->vertexBuffers.clear();

                if( itor->indexData )
                {
                    OGRE_FREE_SIMD( itor->indexData, MEMCATEGORY_GEOMETRY );
                    itor->indexData = 0;
                }

                ++itor;
            }

            //TODO: Delete created mVaos. Don't erase the data from those vaos?

            throw;
        }

        popInnerChunk(stream);    }



void VoxMeshSerializer::readSubMeshLod( DataStreamPtr& stream, Mesh *pMesh, SubMeshLod *subLod, uint8 currentLod )
{
    readIndexes( stream, subLod );

    pushInnerChunk(stream);

    subLod->operationType = OT_TRIANGLE_LIST;

    uint16 streamID = readChunk(stream);
    while( !stream->eof() &&
           (streamID == M_SUBMESH_M_GEOMETRY ||
            streamID == M_SUBMESH_M_GEOMETRY_EXTERNAL_SOURCE ||
            streamID == M_SUBMESH_LOD_OPERATION ) )
    {
        switch( streamID )
        {
        case M_SUBMESH_M_GEOMETRY:
            if( subLod->lodSource != currentLod )
            {
                OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                    "Submesh contains both M_SUBMESH_M_GEOMETRY and "
                    "M_SUBMESH_M_GEOMETRY_EXTERNAL_SOURCE streams. They're mutually exclusive. " +
                     pMesh->getName(),
                    "MeshSerializerImpl::readSubMeshLod" );
            }
            readGeometry( stream, subLod );
            break;

        case M_SUBMESH_M_GEOMETRY_EXTERNAL_SOURCE:
            if( !subLod->vertexBuffers.empty() || !subLod->vertexDeclarations.empty() )
            {
                OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                    "Submesh contains both M_SUBMESH_M_GEOMETRY_EXTERNAL_SOURCE "
                    "and M_SUBMESH_M_GEOMETRY streams. They're mutually exclusive. " +
                     pMesh->getName(),
                    "MeshSerializerImpl::readSubMeshLod" );
            }

            readChar( stream, &subLod->lodSource );
            break;

        case M_SUBMESH_LOD_OPERATION:
            readSubMeshLodOperation( stream, subLod );
            break;

        default:
            OGRE_EXCEPT( Exception::ERR_INVALIDPARAMS,
                "Invalid stream in " + pMesh->getName(),
                "MeshSerializerImpl::readSubMeshLod" );
            break;
        }

        // Get next stream
        streamID = readChunk(stream);
    }
    if( !stream->eof() )
    {
        // Backpedal back to start of non-submesh stream
        backpedalChunkHeader(stream);
    }

    popInnerChunk(stream);
}

void VoxMeshSerializer::readIndexes(DataStreamPtr& stream, SubMeshLod *subLod)
{
    assert( !subLod->indexData );

    readInts( stream, &subLod->numIndices, 1 );

    if( subLod->numIndices > 0 )
    {
        readBools( stream, &subLod->index32Bit, 1 );

        if( subLod->index32Bit )
        {
            subLod->indexData = OGRE_MALLOC_SIMD( sizeof(uint32) * subLod->numIndices,
                                                  MEMCATEGORY_GEOMETRY );
            readInts(stream, reinterpret_cast<uint32*>(subLod->indexData), subLod->numIndices);
        }
        else
        {
            subLod->indexData = OGRE_MALLOC_SIMD( sizeof(uint16) * subLod->numIndices,
                                                  MEMCATEGORY_GEOMETRY );
            readShorts(stream, reinterpret_cast<uint16*>(subLod->indexData), subLod->numIndices);
        }
    }
}

void VoxMeshSerializer::readGeometry(DataStreamPtr& stream, SubMeshLod *subLod)
{
    readInts( stream, &subLod->numVertices, 1 );

    uint8 numSources;
    readChar( stream, &numSources );

    subLod->vertexDeclarations.resize( numSources );
    subLod->vertexBuffers.resize( numSources );

    pushInnerChunk( stream );

    uint16 streamID = readChunk(stream);
    while( !stream->eof() &&
           (streamID == M_SUBMESH_M_GEOMETRY_VERTEX_DECLARATION ||
            streamID == M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER) )
    {
        switch( streamID )
        {
        case M_SUBMESH_M_GEOMETRY_VERTEX_DECLARATION:
            readVertexDeclaration( stream, subLod );
            break;
        case M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER:
            readVertexBuffer( stream, subLod );
            break;
        }
        // Get next stream
        streamID = readChunk(stream);
    }
    if( !stream->eof() )
    {
        // Backpedal back to start of non-submesh stream
        backpedalChunkHeader(stream);
    }

    popInnerChunk( stream );
}
void VoxMeshSerializer::readVertexDeclaration(DataStreamPtr& stream, SubMeshLod *subLod)
{
    VertexElement2VecVec::iterator itor = subLod->vertexDeclarations.begin();
    VertexElement2VecVec::iterator end  = subLod->vertexDeclarations.end();

    while( itor != end )
    {
        uint8 numVertexElements;
        readChar( stream, &numVertexElements );

        itor->reserve( numVertexElements );

        for( uint8 i=0; i<numVertexElements; ++i )
        {
            uint8 type;
            readChar( stream, &type );
            uint8 semantic;
            readChar( stream, &semantic );

            itor->push_back( VertexElement2( static_cast<VertexElementType>( type ),
                                             static_cast<VertexElementSemantic>( semantic ) ) );
        }

        ++itor;
    }
}
void VoxMeshSerializer::readVertexBuffer(DataStreamPtr& stream, SubMeshLod *subLod)
{
    //Source
    uint8 source;
    readChar( stream, &source );

    // Per-vertex size, must agree with declaration at this source
    uint8 bytesPerVertex;
    readChar( stream, &bytesPerVertex );

    const VertexElement2Vec &vertexElements = subLod->vertexDeclarations[source];

    if( bytesPerVertex != VaoManager::calculateVertexSize( vertexElements ) )
    {
        OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR,
                    "Buffer vertex size does not agree with vertex declaration",
                    "MeshSerializerImpl::readVertexBuffer");
    }

    if( subLod->vertexBuffers[source] )
    {
        OGRE_EXCEPT(Exception::ERR_INTERNAL_ERROR,
                    "Two vertex buffer streams are assigned to the same source."
                    " This mesh is invalid.",
                    "MeshSerializerImpl::readVertexBuffer");
    }

    uint8 *vertexData = reinterpret_cast<uint8*>( OGRE_MALLOC_SIMD(
                            sizeof(uint8) * bytesPerVertex * subLod->numVertices,
                            MEMCATEGORY_GEOMETRY ) );
    subLod->vertexBuffers[source] = vertexData;


    stream->read( vertexData, bytesPerVertex * subLod->numVertices );

    // Endian conversion
    flipLittleEndian( vertexData, subLod->numVertices, bytesPerVertex, vertexElements );
}

void VoxMeshSerializer::flipLittleEndian( void* pData, VertexBufferPacked *vertexBuffer )
{
    flipLittleEndian( pData, vertexBuffer->getNumElements(), vertexBuffer->getBytesPerElement(),
                      vertexBuffer->getVertexElements() );
}
//---------------------------------------------------------------------
void VoxMeshSerializer::flipLittleEndian( void* pData, size_t numVertices, size_t bytesPerVertex,
                                           const VertexElement2Vec &vertexElements )
{
    if (mFlipEndian)
    {
        VertexElement2Vec::const_iterator itElement = vertexElements.begin();
        VertexElement2Vec::const_iterator enElement = vertexElements.end();

        size_t accumulatedOffset = 0;
        while( itElement != enElement )
        {
            flipEndian( pData, numVertices, bytesPerVertex,
                        accumulatedOffset, itElement->mType );

            accumulatedOffset += v1::VertexElement::getTypeSize( itElement->mType );
            ++itElement;
        }
    }
}
void VoxMeshSerializer::flipEndian( void* pData, size_t vertexCount,
                                     size_t vertexSize, size_t baseOffset,
                                     const VertexElementType elementType )
{
    void *pBase = static_cast<uint8*>(pData) + baseOffset;

    size_t typeCount                = v1::VertexElement::getTypeCount( elementType );
    size_t typeSingleMemberSize     = v1::VertexElement::getTypeSize( elementType ) / typeCount;

    if( elementType == VET_BYTE4 || elementType == VET_BYTE4_SNORM ||
        elementType == VET_UBYTE4 || elementType == VET_UBYTE4_NORM )
    {
        // NO FLIPPING
        return;
    }

    for( size_t v = 0; v < vertexCount; ++v )
    {
        Bitwise::bswapChunks( pBase, typeSingleMemberSize, typeCount );

        pBase = static_cast<void*>(
            static_cast<unsigned char*>(pBase) + vertexSize);
    }
}
void VoxMeshSerializer::readSubMeshLodOperation( DataStreamPtr& stream, SubMeshLod *subLod )
{
    // uint16 operationType
    uint16 opType;
    readShorts(stream, &opType, 1);
    subLod->operationType = static_cast<OperationType>(opType);
}

void VoxMeshSerializer::createSubMeshVao( SubMesh *sm, SubMeshLodVec &submeshLods, uint8 casterPass )
{
    sm->mVao[casterPass].reserve( submeshLods.size() );

    VertexBufferPackedVec vertexBuffers;
    for( size_t i=0; i<submeshLods.size(); ++i )
    {
        const SubMeshLod& subMeshLod = submeshLods[i];

        vertexBuffers.clear();
        vertexBuffers.reserve( subMeshLod.vertexBuffers.size() );

        assert( subMeshLod.vertexBuffers.size() == subMeshLod.vertexDeclarations.size() );

        if( subMeshLod.lodSource == i )
        {
            if( subMeshLod.vertexDeclarations.size() == 1 )
            {
                VertexBufferPacked *vertexBuffer = mVaoManager->createVertexBuffer(
                    subMeshLod.vertexDeclarations[0], subMeshLod.numVertices, sm->mParent->getVertexBufferDefaultType(),
                    subMeshLod.vertexBuffers[0], sm->mParent->isVertexBufferShadowed() );

                if( !sm->mParent->isVertexBufferShadowed() )
                {
                    OGRE_FREE_SIMD( submeshLods[i].vertexBuffers[0], MEMCATEGORY_GEOMETRY );
                    submeshLods[i].vertexBuffers.erase( submeshLods[i].vertexBuffers.begin() );
                }

                vertexBuffers.push_back( vertexBuffer );
            }
            else
            {
                OGRE_EXCEPT( Exception::ERR_NOT_IMPLEMENTED,
                             "Meshes with multiple vertex buffer sources aren't yet supported."
                             " Load it as v1 mesh and import it to a v2 mesh",
                             "MeshSerializerImpl::createSubMeshVao" );
#ifdef _OGRE_MULTISOURCE_VBO
                /*TODO: Support this, also grab an existing pool that can
                handle our request before trying to create a new one.
                MultiSourceVertexBufferPool *multiSourcePool = mVaoManager->
                        createMultiSourceVertexBufferPool(
                            subMeshLod.vertexDeclarations[0],
                            std::max( defaultMaxNumVertices, subMeshLod.numVertices ), BT_IMMUTABLE );

                for( size_t j=0; j<subMeshLod.vertexBuffers.size(); ++j )
                {
                    void * const *initialData = reinterpret_cast<void*const*>(
                                                    &subMeshLod.vertexBuffers[0] );
                    multiSourcePool->createVertexBuffers( vertexBuffers, subMeshLod.numVertices,
                                                          initialData, true );
                }*/
#endif
            }
        }
        else
        {
            vertexBuffers = sm->mVao[casterPass][subMeshLod.lodSource]->getVertexBuffers();
        }

        IndexBufferPacked *indexBuffer = 0;
        if( subMeshLod.indexData )
        {
            indexBuffer = mVaoManager->createIndexBuffer(
                                subMeshLod.index32Bit ? IndexBufferPacked::IT_32BIT :
                                                        IndexBufferPacked::IT_16BIT,
                                subMeshLod.numIndices, sm->mParent->getIndexBufferDefaultType(),
                                subMeshLod.indexData, sm->mParent->isIndexBufferShadowed() );

            if( !sm->mParent->isIndexBufferShadowed() )
            {
                OGRE_FREE_SIMD( subMeshLod.indexData, MEMCATEGORY_GEOMETRY );
                submeshLods[ i ].indexData = 0;
            }
        }

        VertexArrayObject *vao = mVaoManager->createVertexArrayObject( vertexBuffers, indexBuffer,
                                                                       subMeshLod.operationType );

        sm->mVao[casterPass].push_back( vao );
    }
}



VoxMeshSerializer::SubMeshLod::SubMeshLod() :
    numVertices( 0 ),
    lodSource( 0 ),
    index32Bit( false ),
    numIndices( 0 ),
    indexData( 0 )
{
}



}
