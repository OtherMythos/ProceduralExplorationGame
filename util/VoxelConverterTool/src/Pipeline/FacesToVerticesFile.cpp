#include "FacesToVerticesFile.h"

#include "Pipeline/VoxToFaces.h"

#include <cstring>
#include <cassert>
#include <math.h>

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
        {
            writeBounds(outFaces);
        }
    }

    void FacesToVerticesFile::writeBounds(const OutputFaces& outFaces){

        int minX = outFaces.minX - 128;
        int minY = outFaces.minY - 128;
        int minZ = outFaces.minZ - 128;
        int maxX = outFaces.maxX - 128;
        int maxY = outFaces.maxY - 128;
        int maxZ = outFaces.maxZ - 128;
        assert( (minX <= maxX && minY <= maxY && minZ <= maxZ) &&
                "The minimum corner of the box must be less than or equal to maximum corner" );
        float centreX = (maxX + minX) * 0.5;
        float centreY = (maxY + minY) * 0.5;
        float centreZ = (maxZ + minZ) * 0.5;

        float halfX = (maxX - minX) * 0.5;
        float halfY = (maxY - minY) * 0.5;
        float halfZ = (maxZ - minZ) * 0.5;

        //Values taken from OgreMesh2SerializerImpl
        const long MSTREAM_OVERHEAD_SIZE = sizeof(uint16) + sizeof(uint32);
        unsigned long size = MSTREAM_OVERHEAD_SIZE;
        size += sizeof(float) * 7;
        writeChunkHeader(M_MESH_BOUNDS, size);
        writeFloats(&centreX, 1);
        writeFloats(&centreY, 1);
        writeFloats(&centreZ, 1);

        writeFloats(&halfX, 1);
        writeFloats(&halfY, 1);
        writeFloats(&halfZ, 1);

        float dotProduct = (halfX * halfX) + (halfY * halfY) + (halfZ * halfZ);
        float radius = sqrtf(dotProduct);
        writeFloats(&radius, 1);
    }

}
