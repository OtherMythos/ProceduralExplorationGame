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

    static const Ogre::VertexElement2Vec elemVec = {
        Ogre::VertexElement2(Ogre::VET_FLOAT3, Ogre::VES_POSITION),
        Ogre::VertexElement2(Ogre::VET_FLOAT1, Ogre::VES_NORMAL),
        Ogre::VertexElement2(Ogre::VET_FLOAT2, Ogre::VES_TEXTURE_COORDINATES),
    };

    Voxeliser::Voxeliser(){

    }

    Voxeliser::~Voxeliser(){

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
                RegionBufferEntry& bufEntry = regionEntries[regionId];

                float voxFloat = (float)(vox & 0xFF);
                if(voxFloat <= seaLevel){
                    altitudes[x+y*width] = -1.0f;
                    continue;
                }

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
                RegionBufferEntry& bufEntry = regionEntries[regionId];
                float vox = altitudes[x+y*width];
                if(vox == -1.0f) continue;
                //If the voxel altitude isn't 0 then there must be active voxels.
                assert(bufEntry.mNumActiveVox > 0);
                //TODO optimistion try and make this loop only consider the secondary voxel, for the sake of cache efficiency.
                AV::uint32 altitude = *reinterpret_cast<AV::uint32*>(&vox) & 0xFFFF;
                AV::uint8 v = (*reinterpret_cast<AV::uint32*>(&vox) >> 16) & 0xFF;

                AV::uint32 yInverse = y;

                //TODO shift this logic off somewhere else in memory.
                float texCoordX = (static_cast<float>(v % COLS_WIDTH) / COLS_WIDTH) + TILE_WIDTH;
                float texCoordY = ((static_cast<float>(v) / COLS_WIDTH) / COLS_HEIGHT) + TILE_HEIGHT;

                //write the upwards face
                {
                    AV::uint32 f = 3;
                    AV::uint32 ambientMask = getVerticeBorderTerrain(altitude, altitudes, f, x, y, width);
                    for(AV::uint32 i = 0; i < 4; i++){
                        AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                        AV::uint32 xx = (VERTICES_POSITIONS[fv] + x);
                        AV::uint32 yy = (VERTICES_POSITIONS[fv + 1] + yInverse);
                        AV::uint32 zz = (VERTICES_POSITIONS[fv + 2] + altitude);

                        AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                        assert(ambient >= 0 && ambient <= 3);

                        AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                        (*bufEntry.mVertsWritePtr++) = val;
                        val = f << 29 | 0x15FBF7DB;
                        (*bufEntry.mVertsWritePtr++) = val;
                        (*bufEntry.mVertsWritePtr++) = 0x0;
                        (*bufEntry.mVertsWritePtr++) = 0x0;
                        *reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordX;
                        *reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordY;
                    }
                    bufEntry.mNumTris += 2;
                    bufEntry.mNumVerts += 4;
                }
                //Calculate the remaining altitude faces
                writeFaceToMesh(x, y-1, x, yInverse, 0, altitude, altitudes, width, height, texCoordX, texCoordY, bufEntry);
                writeFaceToMesh(x, y+1, x, yInverse, 1, altitude, altitudes, width, height, texCoordX, texCoordY, bufEntry);
                writeFaceToMesh(x+1, y, x, yInverse, 4, altitude, altitudes, width, height, texCoordX, texCoordY, bufEntry);
                writeFaceToMesh(x-1, y, x, yInverse, 5, altitude, altitudes, width, height, texCoordX, texCoordY, bufEntry);
            }
        }

        for(RegionId i = 0; i < numRegions; i++){
            RegionBufferEntry& bufEntry = regionEntries[i];
            Ogre::MeshPtr mesh = bufEntry.generateMesh(meshName, mapData->width, mapData->height, maxAltitude);
            *outMeshes++ = mesh;
        }

        *outNumRegions = numRegions;
    }

    void Voxeliser::writeFaceToMesh(AV::uint32 targetX, AV::uint32 targetY, AV::uint32 x, AV::uint32 y, AV::uint32 f, AV::uint32 altitude, const std::vector<float>& altitudes, AV::uint32 width, AV::uint32 height, float texCoordX, float texCoordY, RegionBufferEntry& bufEntry) const{
        //Assuming there's no voxels around the outskirt this check can be avoided.
        //if(!(targetX < 0 || targetY < 0 || targetX >= width || targetY >= height)){
            float vox = altitudes[targetX + targetY * width];
            if(vox != -1.0f){
                AV::uint32 testAltitude = *reinterpret_cast<AV::uint32*>(&vox) & 0xFFFF;
                if(testAltitude < altitude){
                    //The altidue is lower so need to draw some triangles.
                    AV::uint32 altitudeDelta = altitude - testAltitude;
                    for(AV::uint32 zAlt = 0; zAlt < altitudeDelta; zAlt++){
                        //Loop down and draw the triangles.

                        AV::uint32 faceAltitude = (altitude-zAlt);
                        AV::uint32 ambientMask = getVerticeBorderTerrain(faceAltitude, altitudes, f, x, y, width);
                        for(AV::uint32 i = 0; i < 4; i++){
                            AV::uint32 fv = FACES_VERTICES[f * 4 + i]*3;
                            AV::uint32 xx = VERTICES_POSITIONS[fv] + x;
                            AV::uint32 yy = VERTICES_POSITIONS[fv + 1] + y;
                            AV::uint32 zz = VERTICES_POSITIONS[fv + 2] + faceAltitude;

                            AV::uint8 ambient = (ambientMask >> 8 * i) & 0xFF;
                            assert(ambient >= 0 && ambient <= 3);

                            AV::uint32 val = xx | yy << 10 | zz << 20 | ambient << 30;
                            //TODO Magic number for now to avoid it breaking the regular materials.
                            (*bufEntry.mVertsWritePtr++) = val;
                            val = f << 29 | 0x15FBF7DB;
                            (*bufEntry.mVertsWritePtr++) = val;
                            (*bufEntry.mVertsWritePtr++) = 0x0;
                            (*bufEntry.mVertsWritePtr++) = 0x0;
                            *reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordX;
                            *reinterpret_cast<float*>(bufEntry.mVertsWritePtr++) = texCoordY;
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

    void RegionBufferEntry::prepareVertBuffer(){
        if(mNumActiveVox == 0){
            return;
        }
        //TODO might be able to switch this to an std::vector to manage the correct sizing.
        mVerts = malloc( (size_t)(mNumActiveVox * (((NUM_VERTS * 4) * 5) * 4) * 2.5) );
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
        void* indices = malloc(static_cast<size_t>(vertBlocks * 6 * indiceStride));
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
