#include "Voxeliser.h"

#include "MapGen/ExplorationMapDataPrerequisites.h"

#include <cassert>
#include "Ogre.h"
#include "OgreMeshManager2.h"
#include "OgreMesh2.h"
#include "OgreRenderSystem.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"

namespace ProceduralExplorationGameCore{

    static const int OCEAN_EDGE_LENGTH = 4;

    static const Ogre::VertexElement2Vec elemVec = {
        Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_POSITION),
        //Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_POSITION),
        //Ogre::VertexElement2(Ogre::VET_FLOAT1, Ogre::VES_NORMAL),
        //Ogre::VertexElement2(Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES),
    };

    Voxeliser::Voxeliser(){

    }

    Voxeliser::~Voxeliser(){

    }

    inline bool blockIsFaceVisible(AV::uint8 mask, int f){
        return 0 == ((1 << f) & mask);
    }
    VoxelId Voxeliser::readVoxelFromData_(VoxelId* data, int x, int y, int z, AV::uint32 width, AV::uint32 height){
        return *(data + (x + (y * width) + (z*width*height)));
    }
    AV::uint32 Voxeliser::getVerticeBorder(VoxelId* data, AV::uint8 f, int x, int y, int z, AV::uint32 width, AV::uint32 height, AV::uint32 depth){
        AV::uint32 faceVal = f * 9 * 4;
        AV::uint32 ret = 0;
        for(AV::uint8 v = 0; v < 4; v++){
            AV::uint32 faceBase = faceVal + v * 9;
            AV::uint8 foundValsTemp[3] = {0, 0, 0};
            for(AV::uint8 i = 0; i < 3; i++){
                int xx = VERTICE_BORDERS[faceBase + i * 3];
                int yy = VERTICE_BORDERS[faceBase + i * 3 + 1];
                int zz = VERTICE_BORDERS[faceBase + i * 3 + 2];

                int xPos = x + xx;
                if(xPos < 0 || xPos >= width) continue;
                int yPos = y + yy;
                if(yPos < 0 || yPos >= height) continue;
                int zPos = z + zz;
                if(zPos < 0 || zPos >= depth) continue;

                VoxelId vox = readVoxelFromData_(data, xPos, yPos, zPos, width, height);
                foundValsTemp[i] = vox != EMPTY_VOXEL ? 1 : 0;
            }
            //https://0fps.net/2013/07/03/ambient-occlusion-for-minecraft-like-worlds/
            AV::uint32 val = 0;
            if(foundValsTemp[0] && foundValsTemp[1]){
                val = 0;
            }else{
                val = 3 - (foundValsTemp[0] + foundValsTemp[1] + foundValsTemp[2]);
            }
            assert(val >= 0 && val <= 3);
            //Batch the results for all 4 vertices into the single return value.
            ret = ret | val << (v * 8);
        }
        return ret;
    }
    void Voxeliser::createMeshForVoxelData(const std::string& meshName, VoxelId* data, AV::uint32 width, AV::uint32 height, AV::uint32 depth, Ogre::MeshPtr* outMesh){
        std::vector<AV::uint32> verts;

        AV::uint32 numVerts = 0;

        VoxelId* voxPtr = data;
        for(int z = 0; z < depth; z++)
        for(int y = 0; y < height; y++)
        for(int x = 0; x < width; x++){
            VoxelId v = *voxPtr;
            voxPtr++;
            if(v == EMPTY_VOXEL) continue;
            //float texCoordX = (static_cast<float>(v % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH;
            //float texCoordY = (static_cast<float>((static_cast<AV::uint32>(static_cast<float>(v) / COLS_WIDTH))) / COLS_HEIGHT) + TILE_HEIGHT;
            AV::uint8 neighbourMask = getNeighbourMask(data, x, y, z, width, height, depth);
            for(int f = 0; f < 6; f++){
                if(!blockIsFaceVisible(neighbourMask, f)) continue;
                //if((1 << f) & mFaceExclusionMask_) continue;
                AV::uint32 ambientMask = getVerticeBorder(data, f, x, y, z, width, height, depth);
                for(int i = 0; i < 4; i++){
                    //Pack everything into a single integer.
                    AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                    int xx = (VERTICES_POSITIONS[fv] + x);
                    int yy = (VERTICES_POSITIONS[fv + 1] + y);
                    int zz = (VERTICES_POSITIONS[fv + 2] + z);
                    assert(xx <= 0x2FF && xx >= -0x2FF);
                    assert(yy <= 0x2FF && yy >= -0x2FF);
                    assert(zz <= 0x2FF && zz >= -0x2FF);

                    AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                    assert(ambient >= 0 && ambient <= 3);

                    AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                    verts.push_back(val);

                    val = f << 29 | v;
                    //val = f;
                    verts.push_back(val);
                    //verts.push_back(f);
                    verts.push_back(0);
                    //TODO just to pad it out, long term I shouldn't need this.
                    //verts.push_back(0);

                    //verts.push_back(*(reinterpret_cast<AV::uint32*>(&texCoordX)));
                    //verts.push_back(*(reinterpret_cast<AV::uint32*>(&texCoordY)));
                }
                numVerts += 4;
            }
        }

        //Generate the mesh

        if(verts.empty()){
            outMesh->reset();
            return;
        }
        Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().createManual(meshName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        Ogre::SubMesh* subMesh = mesh->createSubMesh();

        AV::uint32 numFaces = numVerts / 4;
        //TODO OPTIMISATION properly set the indice stride to either be 16 or 32 bit.
        static const size_t indiceStride = 4;
        void* indices = OGRE_MALLOC_SIMD(static_cast<size_t>(numFaces * 6 * indiceStride), Ogre::MEMCATEGORY_GEOMETRY);
        AV::uint32* indicesPtr = static_cast<AV::uint32*>(indices);
        //size_t indiceStride = (numFaces * 6 * 4) + 4 >= 0xFFFF ? 4 : 2;
        for(AV::uint32 i = 0; i < numFaces; i++){
            AV::uint32 currIndex = i * 4;
            *(indicesPtr++) = currIndex + 0;
            *(indicesPtr++) = currIndex + 1;
            *(indicesPtr++) = currIndex + 2;
            *(indicesPtr++) = currIndex + 2;
            *(indicesPtr++) = currIndex + 3;
            *(indicesPtr++) = currIndex + 0;
        }

        void* vertsMem = OGRE_MALLOC_SIMD(static_cast<size_t>(verts.size() * sizeof(AV::uint32)), Ogre::MEMCATEGORY_GEOMETRY);
        AV::uint32* vertsPtr = static_cast<AV::uint32*>(vertsMem);
        memcpy(vertsPtr, &(verts[0]), verts.size() * sizeof(AV::uint32));

        Ogre::VertexBufferPacked *vertexBuffer = 0;
        Ogre::RenderSystem *renderSystem = Ogre::Root::getSingletonPtr()->getRenderSystem();
        Ogre::VaoManager *vaoManager = renderSystem->getVaoManager();
        try{
            vertexBuffer = vaoManager->createVertexBuffer(elemVec, numVerts, Ogre::BT_DEFAULT, vertsMem, true);
        }catch(Ogre::Exception &e){
            vertexBuffer = 0;
        }

        Ogre::IndexBufferPacked* indexBuffer = vaoManager->createIndexBuffer(Ogre::IndexType::IT_32BIT, numFaces * 6, Ogre::BT_IMMUTABLE, indices, false);

        Ogre::VertexBufferPackedVec vertexBuffers;
        vertexBuffers.push_back(vertexBuffer);
        Ogre::VertexArrayObject* arrayObj = vaoManager->createVertexArrayObject(vertexBuffers, indexBuffer, Ogre::OT_TRIANGLE_LIST);

        subMesh->mVao[Ogre::VpNormal].push_back(arrayObj);
        subMesh->mVao[Ogre::VpShadow].push_back(arrayObj);

        const Ogre::Vector3 halfBounds(width/2, height/2, depth/2);
        const Ogre::Aabb bounds(halfBounds, halfBounds);
        mesh->_setBounds(bounds);
        mesh->_setBoundingSphereRadius(bounds.getRadius());

        //subMesh->setMaterialName("baseVoxelMaterial");

        *outMesh = mesh;

    }
    AV::uint8 Voxeliser::getNeighbourMask(VoxelId* data, int x, int y, int z, AV::uint32 width, AV::uint32 height, AV::uint32 depth){
        int ret = 0;
        for(int v = 0; v < 6; v++){
            int xx = MASKS[v * 3];
            int yy = MASKS[v * 3 + 1];
            int zz = MASKS[v * 3 + 2];

            int xPos = x + xx;
            if(xPos < 0 || xPos >= width) continue;
            int yPos = y + yy;
            if(yPos < 0 || yPos >= height) continue;
            int zPos = z + zz;
            if(zPos < 0 || zPos >= depth) continue;

            VoxelId vox = readVoxelFromData_(data, xPos, yPos, zPos, width, height);
            if(vox != EMPTY_VOXEL){
                ret = ret | (1 << v);
            }
        }
        return ret;
    }

    void Voxeliser::writeFaceToMeshVisitedPlace(int targetX, int targetY, AV::uint32 xVal, AV::uint32 yVal, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint8 altitude, const std::vector<AV::uint8>& altitudes, AV::uint32 width, AV::uint32 height, AV::uint8 v, AV::uint32 totalWidth, AV::uint32 totalHeight, RegionBufferEntry& bufEntry) const{
        if(targetX < 0 || targetY < 0 || targetX >= totalWidth || targetY >= totalHeight) return;
        AV::uint8 testAltitude = altitudes[targetX + targetY * totalWidth];
        if(testAltitude <= 0) return;

        if(testAltitude < altitude){
            //The altidue is lower so need to draw some triangles.
            AV::uint32 altitudeDelta = altitude - testAltitude;
            for(AV::uint32 zAlt = 0; zAlt < altitudeDelta; zAlt++){
                //Loop down and draw the triangles.

                AV::uint32 faceAltitude = (altitude-zAlt);
                //AV::uint32 ambientMask = getVerticeBorderTerrain(faceAltitude, altitudes, f, x, y, width);
                AV::uint32 ambientMask = 0x0;
                for(AV::uint32 i = 0; i < 4; i++){
                    AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                    AV::uint32 xx = VERTICES_POSITIONS[fv] + x - xVal;
                    AV::uint32 yy = VERTICES_POSITIONS[fv + 1] + y - yVal;
                    AV::uint32 zz = VERTICES_POSITIONS[fv + 2] + faceAltitude;

                    AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                    assert(ambient >= 0 && ambient <= 3);

                    AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                    (*bufEntry.mVertsWritePtr++) = val;
                    val = f << 29 | v;
                    (*bufEntry.mVertsWritePtr++) = val;
                    (*bufEntry.mVertsWritePtr++) = 0x0;
                    //(*bufEntry.mVertsWritePtr++) = 0x0;
                    //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordX;
                    //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordY;
                }
                bufEntry.mNumTris += 2;
                bufEntry.mNumVerts+=4;
            }
        }
    }
    void Voxeliser::createTerrainFromVisitedPlaceMapData(const std::string& meshName, VisitedPlaceMapData* mapData, Ogre::MeshPtr* outMesh, AV::uint32 xVal, AV::uint32 yVal, AV::uint32 widthVal, AV::uint32 heightVal){
        //Probably no need to go through and collect the altitude values, they're already close enough.
        //All the same destination.

        RegionBufferEntry outBuffer;

        outBuffer.mNumActiveVox = widthVal * heightVal;
        outBuffer.prepareVertBuffer();

        int maxAltitude = 1;
        for(AV::uint32 y = yVal; y < yVal + heightVal; y++){
            for(AV::uint32 x = xVal; x < xVal + widthVal; x++){
                AV::uint8 altitude = mapData->altitudeValues[x + y * mapData->width];
                AV::uint8 v = mapData->voxelValues[x + y * mapData->width];
                if(altitude == 0) continue;

                if(altitude > maxAltitude) maxAltitude = altitude;

                AV::uint32 yInverse = y;

                //float texCoordX = (static_cast<float>(v % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH;
                //float texCoordY = (static_cast<float>((static_cast<AV::uint32>(static_cast<float>(v) / COLS_WIDTH))) / COLS_HEIGHT) + TILE_HEIGHT;

                {
                    AV::uint32 f = 3;
                    AV::uint32 ambientMask = getVerticeBorderTerrainVisitedPlaces(altitude, mapData->altitudeValues, f, x, y, mapData->width, mapData->height);
                    for(AV::uint32 i = 0; i < 4; i++){
                        AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                        AV::uint32 xx = (VERTICES_POSITIONS[fv] + x) - xVal;
                        AV::uint32 yy = (VERTICES_POSITIONS[fv + 1] + yInverse) - yVal;
                        AV::uint32 zz = (VERTICES_POSITIONS[fv + 2] + altitude);

                        AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                        assert(ambient >= 0 && ambient <= 3);

                        AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                        (*outBuffer.mVertsWritePtr++) = val;
                        val = f << 29 | v;
                        (*outBuffer.mVertsWritePtr++) = val;
                        (*outBuffer.mVertsWritePtr++) = 0x0;
                        //(*outBuffer.mVertsWritePtr++) = 0x0;
                        //*reinterpret_cast<float*>(outBuffer.mVertsWritePtr++) = texCoordX;
                        //*reinterpret_cast<float*>(outBuffer.mVertsWritePtr++) = texCoordY;
                    }
                    outBuffer.mNumTris += 2;
                    outBuffer.mNumVerts += 4;
                }
                writeFaceToMeshVisitedPlace(x, (int)y-1, xVal, yVal, x, yInverse, 0, altitude, mapData->altitudeValues, widthVal, heightVal, v, mapData->width, mapData->height, outBuffer);
                writeFaceToMeshVisitedPlace(x, (int)y+1, xVal, yVal, x, yInverse, 1, altitude, mapData->altitudeValues, widthVal, heightVal, v, mapData->width, mapData->height, outBuffer);
                writeFaceToMeshVisitedPlace((int)x+1, y, xVal, yVal, x, yInverse, 4, altitude, mapData->altitudeValues, widthVal, heightVal, v, mapData->width, mapData->height, outBuffer);
                writeFaceToMeshVisitedPlace((int)x-1, y, xVal, yVal, x, yInverse, 5, altitude, mapData->altitudeValues, widthVal, heightVal, v, mapData->width, mapData->height, outBuffer);
            }
        }

        *outMesh = outBuffer.generateMesh(meshName, widthVal, heightVal, maxAltitude);
    }

    void Voxeliser::createTerrainFromMapData(const std::string& meshName, ExplorationMapData* mapData, Ogre::MeshPtr* outMeshes, AV::uint32* outNumRegions){
        AV::uint32 width = mapData->width;
        AV::uint32 height = mapData->height;
        AV::uint32 seaLevel = mapData->seaLevel;
        AV::uint32* voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        AV::uint32* secondaryVoxPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);

        static const AV::uint32 WORLD_DEPTH = 20;
        static const AV::uint32 ABOVE_GROUND = 0xFF - seaLevel;

        size_t numRegions = mapData->regionData.size();
        if(numRegions == 0) numRegions = 1;
        std::vector<RegionBufferEntry> regionEntries;
        regionEntries.resize(numRegions);
        for(size_t i = 0; i < numRegions; i++){
            regionEntries[i].mId = i;
        }

        int maxAltitude = 1;
        std::vector<float> altitudes;
        altitudes.resize(width * height);
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                AV::uint32 vox = static_cast<AV::uint32>(*voxPtr);
                AV::uint32 voxSecondary = static_cast<AV::uint32>(*secondaryVoxPtr);
                AV::uint8 regionId = static_cast<AV::uint8>((voxSecondary >> 8) & 0xFF);
                voxPtr++;
                secondaryVoxPtr++;

                float voxFloat = (float)(vox & 0xFF);
                if(voxFloat < seaLevel){
                    altitudes[x+y*width] = -1.0f;
                    continue;
                }

                RegionBufferEntry& bufEntry = regionEntries[regionId];

                AV::uint8 altitude = static_cast<AV::uint8>(((voxFloat - (float)seaLevel) / (float)ABOVE_GROUND) * (float)WORLD_DEPTH) + 1;
                AV::uint8 voxelMeta = (vox >> 8) & static_cast<AV::uint8>(MAP_VOXEL_MASK);
                AV::uint8 v = MapVoxelColour[voxelMeta];
                bool isRiver = (vox >> 8) & static_cast<AV::uint8>(MapVoxelTypes::RIVER);
                if(isRiver){
                    if(altitude <= 3){
                        altitude = 1;
                    }else{
                        altitude -= 2;
                    }
                    v = 192;
                }

                if(altitude > maxAltitude) maxAltitude = altitude;

                *reinterpret_cast<AV::uint32*>(&altitudes[x+y*width]) = altitude | static_cast<AV::uint32>(v) << 16;
                bufEntry.mNumActiveVox++;
            }
        }

        for(size_t i = 0; i < numRegions; i++){
            regionEntries[i].prepareVertBuffer();
        }

        voxPtr = static_cast<AV::uint32*>(mapData->voxelBuffer);
        secondaryVoxPtr = static_cast<AV::uint32*>(mapData->secondaryVoxelBuffer);
        for(AV::uint32 y = 0; y < height; y++){
            for(AV::uint32 x = 0; x < width; x++){
                AV::uint32 voxSecondary = static_cast<AV::uint32>(*secondaryVoxPtr);
                AV::uint8 regionId = static_cast<AV::uint8>((voxSecondary >> 8) & 0xFF);
                voxPtr++;
                secondaryVoxPtr++;
                float vox = altitudes[x+y*width];
                if(vox == -1.0f) continue;
                    RegionBufferEntry& bufEntry = regionEntries[regionId];
                //If the voxel altitude isn't 0 then there must be active voxels.
                assert(bufEntry.mNumActiveVox > 0);
                //TODO optimistion try and make this loop only consider the secondary voxel, for the sake of cache efficiency.
                AV::uint32 altitude = *reinterpret_cast<AV::uint32*>(&vox) & 0xFFFF;
                AV::uint8 v = (*reinterpret_cast<AV::uint32*>(&vox) >> 16) & 0xFF;

                AV::uint32 yInverse = y;

                //TODO shift this logic off somewhere else in memory.
                //float texCoordX = (static_cast<float>(v % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH;
                //float texCoordY = (static_cast<float>((static_cast<AV::uint32>(static_cast<float>(v) / COLS_WIDTH))) / COLS_HEIGHT) + TILE_HEIGHT;

                //write the upwards face
                {
                    AV::uint32 f = 3;
                    AV::uint32 ambientMask = getVerticeBorderTerrain(altitude, altitudes, f, x, y, width);
                    for(AV::uint32 i = 0; i < 4; i++){
                        AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                        AV::uint32 xx = (VERTICES_POSITIONS[fv] + x);
                        AV::uint32 yy = (VERTICES_POSITIONS[fv + 1] + yInverse);
                        AV::uint32 zz = (VERTICES_POSITIONS[fv + 2] + altitude + OCEAN_EDGE_LENGTH);

                        AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                        assert(ambient >= 0 && ambient <= 3);

                        AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                        (*bufEntry.mVertsWritePtr++) = val;
                        val = f << 29 | v;
                        (*bufEntry.mVertsWritePtr++) = val;
                        (*bufEntry.mVertsWritePtr++) = 0x0;
                        //(*bufEntry.mVertsWritePtr++) = 0x0;
                        //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordX;
                        //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordY;
                    }
                    bufEntry.mNumTris += 2;
                    bufEntry.mNumVerts += 4;
                }
                //Calculate the remaining altitude faces
                writeFaceToMesh(x, (int)y-1, x, yInverse, 0, altitude, altitudes, width, height, v, bufEntry);
                writeFaceToMesh(x, (int)y+1, x, yInverse, 1, altitude, altitudes, width, height, v, bufEntry);
                writeFaceToMesh((int)x+1, y, x, yInverse, 4, altitude, altitudes, width, height, v, bufEntry);
                writeFaceToMesh((int)x-1, y, x, yInverse, 5, altitude, altitudes, width, height, v, bufEntry);
            }
        }

        for(RegionId i = 0; i < numRegions; i++){
            RegionBufferEntry& bufEntry = regionEntries[i];
            Ogre::MeshPtr mesh = bufEntry.generateMesh(meshName, mapData->width, mapData->height, maxAltitude);
            *outMeshes++ = mesh;
        }

        *outNumRegions = numRegions;
    }

    void Voxeliser::writeFaceToMesh(AV::uint32 targetX, AV::uint32 targetY, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 width, AV::uint32 height, AV::uint8 v, RegionBufferEntry& bufEntry) const{
        //Assuming there's no voxels around the outskirt this check can be avoided.
        //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
            float vox = altitudes[targetX + targetY * width];
            //if(vox != -1.0f){
            {
                AV::uint32 testAltitude = *reinterpret_cast<AV::uint32*>(&vox) & 0xFFFF;
                if(testAltitude < altitude){
                    //The altidue is lower so need to draw some triangles.
                    AV::uint32 altitudeDelta = altitude - testAltitude;
                    //For the faces about to hit the ocean, extend it slightly so more complex water animations can be used.
                    bool lengthen = (testAltitude == 0 && altitude == 1);
                    for(AV::uint32 zAlt = 0; zAlt < altitudeDelta; zAlt++){
                        //Loop down and draw the triangles.

                        AV::uint32 faceAltitude = (altitude-zAlt);
                        AV::uint32 ambientMask = getVerticeBorderTerrain(faceAltitude, altitudes, f, x, y, width);
                        for(AV::uint32 i = 0; i < 4; i++){
                            AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                            AV::uint32 xx = VERTICES_POSITIONS[fv] + x;
                            AV::uint32 yy = VERTICES_POSITIONS[fv + 1] + y;
                            AV::uint32 zz = VERTICES_POSITIONS[fv + 2] * (lengthen ? OCEAN_EDGE_LENGTH : 1) + faceAltitude + OCEAN_EDGE_LENGTH + (lengthen ? -(OCEAN_EDGE_LENGTH-1) : 0);

                            AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                            assert(ambient >= 0 && ambient <= 3);

                            AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                            //TODO Magic number for now to avoid it breaking the regular materials.
                            (*bufEntry.mVertsWritePtr++) = val;
                            val = f << 29 | v;
                            (*bufEntry.mVertsWritePtr++) = val;
                            (*bufEntry.mVertsWritePtr++) = 0x0;
                            //(*bufEntry.mVertsWritePtr++) = 0x0;
                            //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordX;
                            //*reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordY;
                        }
                        bufEntry.mNumTris += 2;
                        bufEntry.mNumVerts+=4;
                    }
                }
            }
        //}
    }

    AV::uint32 Voxeliser::getVerticeBorderTerrain(AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 f, AV::uint32 x, AV::uint32 y, AV::uint32 width) const{
        AV::uint32 faceVal = f * 9 * 4;
        AV::uint32 ret = 0;
        for(AV::uint32 v = 0; v < 4; v++){
            AV::uint32 faceBase = faceVal + v * 9;
            AV::uint8 foundValsTemp[3] = {0x0, 0x0, 0x0};
            for(AV::uint8 i = 0; i < 3; i++){
                int xx = VERTICE_BORDERS[faceBase + i * 3];
                int yy = VERTICE_BORDERS[faceBase + i * 3 + 1];
                int zz = VERTICE_BORDERS[faceBase + i * 3 + 2];

                //Note: Skip the sanity checks assuming the terrain will not touch the side vertices.
                float targetAltitude = altitudes[(x + xx) + (y + yy) * width];
                //TODO separate -1.0f into a constant.
                if(targetAltitude == -1.0f) continue;
                AV::uint32 checkAltitude = ( *reinterpret_cast<AV::uint32*>(&targetAltitude) & 0xFFFF);
                foundValsTemp[i] = checkAltitude >= (altitude + zz) ? 1 : 0;
            }
            AV::uint32 val = 0;
            if(foundValsTemp[0] && foundValsTemp[1]){
                val = 0;
            }else{
                val = 3 - (foundValsTemp[0] + foundValsTemp[1] + foundValsTemp[2]);
            }
            assert(val >= 0 && val <= 3);
            ret = ret | val << (v * 8);
        }
        return ret;
    }

    //TODO remove the copy and pasting.
    AV::uint32 Voxeliser::getVerticeBorderTerrainVisitedPlaces(AV::uint32 altitude, const std::vector<AV::uint8>& altitudes, AV::uint32 f, int x, int y, AV::uint32 width, AV::uint32 height) const{
        AV::uint32 faceVal = f * 9 * 4;
        AV::uint32 ret = 0;
        for(AV::uint32 v = 0; v < 4; v++){
            AV::uint32 faceBase = faceVal + v * 9;
            AV::uint8 foundValsTemp[3] = {0x0, 0x0, 0x0};
            for(AV::uint8 i = 0; i < 3; i++){
                int xx = VERTICE_BORDERS[faceBase + i * 3];
                int yy = VERTICE_BORDERS[faceBase + i * 3 + 1];
                int zz = VERTICE_BORDERS[faceBase + i * 3 + 2];

                size_t testIdx = (x + xx) + (y + yy) * width;
                if(testIdx < 0 || testIdx >= width * height) continue;
                AV::uint8 checkAltitude = altitudes[testIdx];
                if(checkAltitude == 0) continue;
                foundValsTemp[i] = checkAltitude >= (altitude + zz) ? 1 : 0;
            }
            AV::uint32 val = 0;
            if(foundValsTemp[0] && foundValsTemp[1]){
                val = 0;
            }else{
                val = 3 - (foundValsTemp[0] + foundValsTemp[1] + foundValsTemp[2]);
            }
            assert(val >= 0 && val <= 3);
            ret = ret | val << (v * 8);
        }
        return ret;
    }

    void RegionBufferEntry::prepareVertBuffer(){
        if(mNumActiveVox == 0){
            return;
        }
        //TODO might be able to switch this to an std::vector to manage the correct sizing.
        mVerts = OGRE_MALLOC_SIMD( (size_t)(mNumActiveVox * (((NUM_VERTS * 4) * 5) * 4) * 2.5) , Ogre::MEMCATEGORY_GEOMETRY);
        mVertsWritePtr = static_cast<AV::uint32*>(mVerts);
    }

    Ogre::MeshPtr RegionBufferEntry::generateMesh(const std::string& meshName, AV::uint32 width, AV::uint32 height, int maxAltitude){
        if(mNumActiveVox == 0){
            Ogre::MeshPtr out;
            out.reset();
            return out;
        }
        std::string totalName = meshName;
        totalName += "-region";
        totalName += std::to_string((int)mId);
        Ogre::MeshPtr mesh = Ogre::MeshManager::getSingleton().createManual(totalName, Ogre::ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
        Ogre::SubMesh* subMesh = mesh->createSubMesh();


        AV::uint32 vertBlocks = mNumVerts / 4;
        //TODO properly set the indice stride to either be 16 or 32 bit.
        static const size_t indiceStride = 4;
        void* indices = OGRE_MALLOC_SIMD(static_cast<size_t>(vertBlocks * 6 * indiceStride), Ogre::MEMCATEGORY_GEOMETRY);
        AV::uint32* indicesPtr = static_cast<AV::uint32*>(indices);
        //size_t indiceStride = (vertBlocks * 6 * 4) + 4 >= 0xFFFF ? 4 : 2;
        for(AV::uint32 i = 0; i < vertBlocks; i++){
            AV::uint32 currIndex = i * 4;
            *(indicesPtr++) = currIndex + 0;
            *(indicesPtr++) = currIndex + 1;
            *(indicesPtr++) = currIndex + 2;
            *(indicesPtr++) = currIndex + 2;
            *(indicesPtr++) = currIndex + 3;
            *(indicesPtr++) = currIndex + 0;
        }

        Ogre::VertexBufferPacked *vertexBuffer = 0;
        Ogre::RenderSystem *renderSystem = Ogre::Root::getSingletonPtr()->getRenderSystem();
        Ogre::VaoManager *vaoManager = renderSystem->getVaoManager();
        try{
            vertexBuffer = vaoManager->createVertexBuffer(elemVec, mNumVerts, Ogre::BT_DEFAULT, mVerts, true);
        }catch(Ogre::Exception &e){
            vertexBuffer = 0;
        }

        Ogre::IndexBufferPacked* indexBuffer = vaoManager->createIndexBuffer(Ogre::IndexType::IT_32BIT, vertBlocks * 6, Ogre::BT_IMMUTABLE, indices, false);

        Ogre::VertexBufferPackedVec vertexBuffers;
        vertexBuffers.push_back(vertexBuffer);
        Ogre::VertexArrayObject* arrayObj = vaoManager->createVertexArrayObject(vertexBuffers, indexBuffer, Ogre::OT_TRIANGLE_LIST);

        subMesh->mVao[Ogre::VpNormal].push_back(arrayObj);
        subMesh->mVao[Ogre::VpShadow].push_back(arrayObj);

        const Ogre::Vector3 halfBounds(width/2, height/2, maxAltitude/2);
        const Ogre::Aabb bounds(halfBounds, halfBounds);
        mesh->_setBounds(bounds);
        mesh->_setBoundingSphereRadius(bounds.getRadius());

        subMesh->setMaterialName("baseVoxelMaterial");

        return mesh;
    }

};
