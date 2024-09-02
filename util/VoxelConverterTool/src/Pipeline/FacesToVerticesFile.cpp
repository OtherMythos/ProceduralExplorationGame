#include "FacesToVerticesFile.h"

#include "Pipeline/VoxToFaces.h"

#include <cstring>

namespace VoxelConverterTool{

    const uint16 HEADER_STREAM_ID = 0x1000;
    const uint16 OTHER_ENDIAN_HEADER_STREAM_ID = 0x0010;

    static const uint32 COLS_WIDTH = 16;
    static const uint32 COLS_HEIGHT = 16;
    static const float TILE_WIDTH = (1.0 / COLS_WIDTH) / 2.0;
    static const float TILE_HEIGHT = (1.0 / COLS_HEIGHT) / 2.0;

    FacesToVerticesFile::FacesToVerticesFile()
        : mFlipEndian(false)
    {

    }

    FacesToVerticesFile::~FacesToVerticesFile(){

    }

    void FacesToVerticesFile::writeToFile(const std::string& filePath, const OutputFaces& outFaces){
        mStream = new std::ofstream();
        mStream->open(filePath);

        writeFileHeader();
        writeMesh(outFaces);

        delete mStream;
    }

    void FacesToVerticesFile::writeFileHeader(void)
    {
        uint16 val = HEADER_STREAM_ID;
        writeShorts(&val, 1);

        std::string mVersion = "[VoxMeshSerializer_v0.6.0]";

        writeString(mVersion);
    }

    void FacesToVerticesFile::writeChunkHeader(uint16 id, size_t size)
    {
#if OGRE_SERIALIZER_VALIDATE_CHUNKSIZE
        if (!mChunkSizeStack.empty()){
            size_t pos = mStream->tell();
            if (pos != static_cast<size_t>(mChunkSizeStack.back()) && mReportChunkErrors){
                LogManager::getSingleton().logMessage("Corrupted chunk detected! Stream name: '" + mStream->getName()
                    + "' Chunk id: " + StringConverter::toString(id));
            }
            mChunkSizeStack.back() = pos + size;
        }
#endif
        writeShorts(&id, 1);
        uint32 uint32size = static_cast<uint32>(size);
        writeInts(&uint32size, 1);
    }

    void FacesToVerticesFile::writeFloats(const float* const pFloat, size_t count)
    {
        if (mFlipEndian)
        {
            float * pFloatToWrite = (float *)malloc(sizeof(float) * count);
            memcpy(pFloatToWrite, pFloat, sizeof(float) * count);

            //flipToLittleEndian(pFloatToWrite, sizeof(float), count);
            writeData(pFloatToWrite, sizeof(float), count);

            free(pFloatToWrite);
        }
        else
        {
            writeData(pFloat, sizeof(float), count);
        }
    }

    void FacesToVerticesFile::writeShorts(const uint16* const pShort, size_t count)
    {
        if(mFlipEndian)
        {
            unsigned short * pShortToWrite = (unsigned short *)malloc(sizeof(unsigned short) * count);
            memcpy(pShortToWrite, pShort, sizeof(unsigned short) * count);

            //flipToLittleEndian(pShortToWrite, sizeof(unsigned short), count);
            writeData(pShortToWrite, sizeof(unsigned short), count);

            free(pShortToWrite);
        }
        else
        {
            writeData(pShort, sizeof(unsigned short), count);
        }
    }

    void FacesToVerticesFile::writeInts(const uint32* const pInt, size_t count = 1)
    {
        if(mFlipEndian)
        {
            uint32 * pIntToWrite = (uint32 *)malloc(sizeof(uint32) * count);
            memcpy(pIntToWrite, pInt, sizeof(uint32) * count);

            //flipToLittleEndian(pIntToWrite, sizeof(uint32), count);
            writeData(pIntToWrite, sizeof(uint32), count);

            free(pIntToWrite);
        }
        else
        {
            writeData(pInt, sizeof(uint32), count);
        }
    }

    void FacesToVerticesFile::writeString(const std::string& string)
    {
        // Old, backwards compatible way - \n terminated
        mStream->write(string.c_str(), string.length());
        // Write terminating newline char
        char terminator = '\n';
        mStream->write(&terminator, 1);
    }

    void FacesToVerticesFile::writeData(const void* const buf, size_t size, size_t count)
    {
        mStream->write(static_cast<const char* const>(buf), size * count);
    }

    //------Mesh specific

    void FacesToVerticesFile::writeMesh(const OutputFaces& outFaces)
    {
        //int exportedLodCount = 1; // generate edge data for original mesh
        //int mNumBufferPasses = pMesh->hasIndependentShadowMappingBuffers() + 1;

        // Header
        size_t meshSizeBytes = outFaces.calcMeshSizeBytes();
        writeChunkHeader(M_SUBMESH_M_GEOMETRY_VERTEX_BUFFER, meshSizeBytes);
        for(WrappedFace f : outFaces.outFaces){
            WrappedFaceContainer fd;
            _unwrapFace(f, fd);

            float texCoordX = (static_cast<float>(fd.vox % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH;
            float texCoordY = (static_cast<float>((static_cast<uint32>(static_cast<float>(fd.vox) / COLS_WIDTH))) / COLS_HEIGHT) + TILE_HEIGHT;

            //Write the four vertices to the file.
            for(int i = 0; i < 4; i++){
                uint32 fv = FACES_VERTICES[fd.faceMask * 4 + i]*3;
                int xx = (VERTICES_POSITIONS[fv] + fd.x);
                int yy = (VERTICES_POSITIONS[fv + 1] + fd.y);
                int zz = (VERTICES_POSITIONS[fv + 2] + fd.z);
                //assert(xx <= 0x2FF && xx >= -0x2FF);
                //assert(yy <= 0x2FF && yy >= -0x2FF);
                //assert(zz <= 0x2FF && zz >= -0x2FF);

                uint8 ambient = (fd.ambientMask >> 4 * i) & 0x3;
                uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                writeInts(&val);
                val = fd.faceMask << 29 | 0x15FBB7DB;
                writeInts(&val);
                val = 0;
                writeInts(&val);
                writeInts(&val);
                writeFloats(&texCoordX, 1);
                writeFloats(&texCoordY, 1);
            }
        }

        size_t indiceBufferSize = outFaces.outFaces.size() * 6 * sizeof(uint32);
        writeChunkHeader(M_SUBMESH_INDEX_BUFFFER, indiceBufferSize);
        for(uint32 i = 0; i < outFaces.outFaces.size(); i++){
            uint32 currentIdx = i * 4;
            uint32 determinedIdx[6] = {
                currentIdx + 0,
                currentIdx + 1,
                currentIdx + 2,
                currentIdx + 2,
                currentIdx + 3,
                currentIdx + 0,
            };
            writeInts(&determinedIdx[0], 6);
        }
        //writeData(&(outFaces.outFaces[0]), sizeof(WrappedFace), outFaces.outFaces.size());
        /*
        {
        writeData( &mNumBufferPasses, 1, 1 ); //unsigned char numPasses

            pushInnerChunk(mStream);

        // Write shared geometry
        for( uint8 i=0; i<mNumBufferPasses; ++i )
        {
            if (pMesh->sharedVertexData[i])
                writeGeometry(pMesh->sharedVertexData[i]);
        }

        // Write Submeshes
        for (unsigned i = 0; i < pMesh->getNumSubMeshes(); ++i)
        {
            LogManager::getSingleton().logMessage("Writing submesh...");
            writeSubMesh(pMesh->getSubMesh(i));
            LogManager::getSingleton().logMessage("Submesh exported.");
        }

        // Write skeleton info if required
        if (pMesh->hasSkeleton())
        {
            LogManager::getSingleton().logMessage("Exporting skeleton link...");
            // Write skeleton link
            writeSkeletonLink(pMesh->getSkeletonName());
            LogManager::getSingleton().logMessage("Skeleton link exported.");

            // Write bone assignments
            if (!pMesh->mBoneAssignments.empty())
            {
                LogManager::getSingleton().logMessage("Exporting shared geometry bone assignments...");

                Mesh::VertexBoneAssignmentList::const_iterator vi;
                for (vi = pMesh->mBoneAssignments.begin();
                vi != pMesh->mBoneAssignments.end(); ++vi)
                {
                    writeMeshBoneAssignment(vi->second);
                }

                LogManager::getSingleton().logMessage("Shared geometry bone assignments exported.");
            }
        }

    #if !OGRE_NO_MESHLOD
        // Write LOD data if any
        if (pMesh->getNumLodLevels() > 1)
        {
            LogManager::getSingleton().logMessage("Exporting LOD information....");
                writeLodLevel(pMesh);
            LogManager::getSingleton().logMessage("LOD information exported.");

        }
    #endif

        // Write bounds information
        LogManager::getSingleton().logMessage("Exporting bounds information....");
        writeBoundsInfo(pMesh);
        LogManager::getSingleton().logMessage("Bounds information exported.");

        // Write submesh name table
        LogManager::getSingleton().logMessage("Exporting submesh name table...");
        writeSubMeshNameTable(pMesh);
        LogManager::getSingleton().logMessage("Submesh name table exported.");

        // Write edge lists
        if (pMesh->isEdgeListBuilt())
        {
            LogManager::getSingleton().logMessage("Exporting edge lists...");
            writeEdgeList(pMesh);
            LogManager::getSingleton().logMessage("Edge lists exported");
        }

        // Write morph animation
        writePoses(pMesh);
        if (pMesh->hasVertexAnimation())
        {
            writeAnimations(pMesh);
        }

        // Write submesh extremes
        writeExtremes(pMesh);
            popInnerChunk(mStream);
        }
         */
    }

}
