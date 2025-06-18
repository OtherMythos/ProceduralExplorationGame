#include "VoxSceneDumper.h"

#include "Ogre.h"
#include "OgreItem.h"
#include "OgreMesh2.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"
#include "Vao/OgreAsyncTicket.h"

#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

#include <cstring>
#include <fstream>
#include <iostream>

namespace ProceduralExplorationGameCore{

    VoxSceneDumper::VoxSceneDumper(){

    }

    VoxSceneDumper::~VoxSceneDumper(){

    }

    struct Colour{
        float r, g, b;
    };

    static const Colour vals[] = {
        {255, 255, 255},
        {255, 255, 204},
        {255, 255, 153},
        {255, 255, 102},
        {255, 255, 51},
        {255, 255, 0},
        {255, 204, 255},
        {255, 204, 204},
        {255, 204, 153},
        {255, 204, 102},
        {255, 204, 51},
        {255, 204, 0},
        {255, 153, 255},
        {255, 153, 204},
        {255, 153, 153},
        {255, 153, 102},
        {255, 153, 51},
        {255, 153, 0},
        {255, 102, 255},
        {255, 102, 204},
        {255, 102, 153},
        {255, 102, 102},
        {255, 102, 51},
        {255, 102, 0},
        {255, 51,  255},
        {255, 51,  204},
        {255, 51,  153},
        {255, 51,  102},
        {255, 51,  51},
        {255, 51,  0},
        {255, 0,   255},
        {255, 0,   204},
        {255, 0,   153},
        {255, 0,   102},
        {255, 0,   51},
        {255, 0,   0},
        {204, 255, 255},
        {204, 255, 204},
        {204, 255, 153},
        {204, 255, 102},
        {204, 255, 51},
        {204, 255, 0},
        {204, 204, 255},
        {204, 204, 204},
        {204, 204, 153},
        {204, 204, 102},
        {204, 204, 51},
        {204, 204, 0},
        {204, 153, 255},
        {204, 153, 204},
        {204, 153, 153},
        {204, 153, 102},
        {204, 153, 51},
        {204, 153, 0},
        {204, 102, 255},
        {204, 102, 204},
        {204, 102, 153},
        {204, 102, 102},
        {204, 102, 51},
        {204, 102, 0},
        {204, 51,  255},
        {204, 51,  204},
        {204, 51,  153},
        {204, 51,  102},
        {204, 51,  51},
        {204, 51,  0},
        {204, 0,   255},
        {204, 0,   204},
        {204, 0,   153},
        {204, 0,   102},
        {204, 0,   51},
        {204, 0,   0},
        {153, 255, 255},
        {153, 255, 204},
        {153, 255, 153},
        {153, 255, 102},
        {153, 255, 51},
        {153, 255, 0},
        {153, 204, 255},
        {153, 204, 204},
        {153, 204, 153},
        {153, 204, 102},
        {153, 204, 51},
        {153, 204, 0},
        {153, 153, 255},
        {153, 153, 204},
        {153, 153, 153},
        {153, 153, 102},
        {153, 153, 51},
        {153, 153, 0},
        {153, 102, 255},
        {153, 102, 204},
        {153, 102, 153},
        {153, 102, 102},
        {153, 102, 51},
        {153, 102, 0},
        {153, 51,  255},
        {153, 51,  204},
        {153, 51,  153},
        {153, 51,  102},
        {153, 51,  51},
        {153, 51,  0},
        {153, 0,   255},
        {153, 0,   204},
        {153, 0,   153},
        {153, 0,   102},
        {153, 0,   51},
        {153, 0,   0},
        {102, 255, 255},
        {102, 255, 204},
        {102, 255, 153},
        {102, 255, 102},
        {102, 255, 51},
        {102, 255, 0},
        {102, 204, 255},
        {102, 204, 204},
        {102, 204, 153},
        {102, 204, 102},
        {102, 204, 51},
        {102, 204, 0},
        {102, 153, 255},
        {102, 153, 204},
        {102, 153, 153},
        {102, 153, 102},
        {102, 153, 51},
        {102, 153, 0},
        {102, 102, 255},
        {102, 102, 204},
        {102, 102, 153},
        {102, 102, 102},
        {102, 102, 51},
        {102, 102, 0},
        {102, 51,  255},
        {102, 51,  204},
        {102, 51,  153},
        {102, 51,  102},
        {102, 51,  51},
        {102, 51,  0},
        {102, 0,   255},
        {102, 0,   204},
        {102, 0,   153},
        {102, 0,   102},
        {102, 0,   51},
        {102, 0,   0},
        {51,  255, 255},
        {51,  255, 204},
        {51,  255, 153},
        {51,  255, 102},
        {51,  255, 51},
        {51,  255, 0},
        {51,  204, 255},
        {51,  204, 204},
        {51,  204, 153},
        {51,  204, 102},
        {51,  204, 51},
        {51,  204, 0},
        {51,  153, 255},
        {51,  153, 204},
        {51,  153, 153},
        {51,  153, 102},
        {51,  153, 51},
        {51,  153, 0},
        {51,  102, 255},
        {51,  102, 204},
        {51,  102, 153},
        {51,  102, 102},
        {51,  102, 51},
        {51,  102, 0},
        {51,  51,  255},
        {51,  51,  204},
        {51,  51,  153},
        {51,  51,  102},
        {51,  51,  51},
        {51,  51,  0},
        {51,  0,   255},
        {51,  0,   204},
        {51,  0,   153},
        {51,  0,   102},
        {51,  0,   51},
        {51,  0,   0},
        {0,   255, 255},
        {0,   255, 204},
        {0,   255, 153},
        {0,   255, 102},
        {0,   255, 51},
        {0,   255, 0},
        {0,   204, 255},
        {0,   204, 204},
        {0,   204, 153},
        {0,   204, 102},
        {0,   204, 51},
        {0,   204, 0},
        {0,   153, 255},
        {0,   153, 204},
        {0,   153, 153},
        {0,   153, 102},
        {0,   153, 51},
        {0,   153, 0},
        {0,   102, 255},
        {0,   102, 204},
        {0,   102, 153},
        {0,   102, 102},
        {0,   102, 51},
        {0,   102, 0},
        {0,   51,  255},
        {0,   51,  204},
        {0,   51,  153},
        {0,   51,  102},
        {0,   51,  51},
        {0,   51,  0},
        {0,   0,   255},
        {0,   0,   204},
        {0,   0,   153},
        {0,   0,   102},
        {0,   0,   51},
        {238, 0,   0},
        {221, 0,   0},
        {187, 0,   0},
        {170, 0,   0},
        {136, 0,   0},
        {119, 0,   0},
        {85,  0,   0},
        {68,  0,   0},
        {34,  0,   0},
        {17,  0,   0},
        {0,   238, 0},
        {0,   221, 0},
        {0,   187, 0},
        {0,   170, 0},
        {0,   136, 0},
        {0,   119, 0},
        {0,   85,  0},
        {0,   68,  0},
        {0,   34,  0},
        {0,   17,  0},
        {0,   0,   238},
        {0,   0,   221},
        {0,   0,   187},
        {0,   0,   170},
        {0,   0,   136},
        {0,   0,   119},
        {0,   0,   85},
        {0,   0,   68},
        {0,   0,   34},
        {0,   0,   17},
        {238, 238, 238},
        {221, 221, 221},
        {187, 187, 187},
        {170, 170, 170},
        {136, 136, 136},
        {119, 119, 119},
        {85,  85,  85},
        {68,  68,  68},
        {34,  34,  34},
        {17,  17,  17},
        {0,   0,   0}
    };


    struct VertexEntry{
        float x, y, z, xn, yn, zn, r, g, b;
    };
    struct FaceEntry{
        size_t a, b;
    };
    struct VoxData{
        std::vector<VertexEntry> verts;
        std::vector<FaceEntry> faces;
    };

    void processObject(Ogre::MovableObject* obj, const Ogre::Matrix4& worldTransform, VoxData& out, std::ofstream* mStream){
        static const Ogre::Vector3 FACES_NORMALS[6] = {
            Ogre::Vector3(0, -1,  0),
            Ogre::Vector3(0,  1,  0),
            Ogre::Vector3(0,  0, -1),
            Ogre::Vector3(0,  0,  1),
            Ogre::Vector3(1,  0,  0),
            Ogre::Vector3(-1, 0,  0),
        };

        const std::string movType = obj->getMovableType();
        if(movType == "VoxMeshItem" || movType == "Item"){
            Ogre::Item* item = dynamic_cast<Ogre::Item*>(obj);
            for(size_t i = 0; i < item->getMesh()->getNumSubMeshes(); i++){
                Ogre::SubMesh* subMesh = item->getMesh()->getSubMesh(i);

                Ogre::Renderable* renderable = item->mRenderables[0];
                if(!renderable->hasCustomParameter(0)) return;
                const Ogre::Vector4& params = renderable->getCustomParameter(0);
                Ogre::uint32 v = *(reinterpret_cast<const Ogre::uint32*>(&params.x));

                const bool packedVoxels = (v & ProceduralExplorationGameCore::HLMS_PACKED_VOXELS);
                const bool terrain = (v & ProceduralExplorationGameCore::HLMS_TERRAIN);
                const bool offlineVoxels = (v & ProceduralExplorationGameCore::HLMS_PACKED_OFFLINE_VOXELS);

                Ogre::VertexArrayObjectArray vaos = subMesh->mVao[Ogre::VpNormal];

                for (auto vao : vaos) {
                    Ogre::VertexBufferPacked* vBuf = vao->getVertexBuffers()[0];
                    Ogre::IndexBufferPacked* iBuf = vao->getIndexBuffer();

                    if (!vBuf || !iBuf) continue;

                    Ogre::VertexElement2Vec elements = vBuf->getVertexElements();
                    size_t vertexCount = vBuf->getNumElements();

                    Ogre::AsyncTicketPtr ticketPtr = vBuf->readRequest(0, vertexCount);
                    const float * RESTRICT_ALIAS vertexData = reinterpret_cast<const float*RESTRICT_ALIAS>(ticketPtr->map());
                    Ogre::AsyncTicketPtr indiceTicketPtr = iBuf->readRequest(0, iBuf->getNumElements());
                    const uint16_t* indexData = static_cast<const uint16_t*>(indiceTicketPtr->map());

                    size_t cc = 0;
                    for (size_t v = 0; v < vertexCount; ++v) {
                        const float* ptr = vertexData + (cc * 3);

                        Ogre::uint32 original = *(reinterpret_cast<const Ogre::uint32*>(ptr));
                        Ogre::uint32 originalSecond = *(reinterpret_cast<const Ogre::uint32*>(ptr) + 1);

                        if(!packedVoxels) continue;

                        int offset = 0;
                        if(offlineVoxels){
                            offset = 128;
                        }

                        int pos_x = int(original & Ogre::uint32(0x3FF)) - offset;
                        int pos_y = int((original >> 10) & Ogre::uint32(0x3FF)) - offset;
                        int pos_z = int((original >> 20) & Ogre::uint32(0x3FF)) - offset;

                        if(terrain){
                            pos_z -= 4;
                        }

                        float texX = *(ptr + 4);
                        float texY = *(ptr + 5);

                        Ogre::uint32 voxelId = originalSecond & 0xFF;

                        Ogre::uint32 norm = Ogre::uint32((originalSecond >> 29) & Ogre::uint32(0x3));
                        Ogre::uint32 ambient = Ogre::uint32((original >> 30) & Ogre::uint32(0x3));

                        Ogre::Vector3 pos = worldTransform * Ogre::Vector3(pos_x, pos_y, pos_z);
                        Ogre::Vector3 normal = worldTransform * FACES_NORMALS[norm];
                        out.verts.push_back({pos.x, pos.y, pos.z, normal.x, normal.y, normal.z,
                            vals[voxelId].r / 255.0f,
                            vals[voxelId].g / 255.0f,
                            vals[voxelId].b / 255.0f,
                        });
                        cc++;
                    }
                }
            }
        }
    }

    void processNode(Ogre::SceneNode* node, VoxData& out, std::ofstream* mStream){
        const Ogre::Matrix4 transform = node->_getFullTransformUpdated();

        auto objIt = node->getAttachedObjectIterator();
        while(objIt.hasMoreElements()){
            Ogre::MovableObject* obj = objIt.getNext();

            processObject(obj, transform, out, mStream);
        }

        auto it = node->getChildIterator();
        while(it.hasMoreElements()){
            Ogre::SceneNode* child = dynamic_cast<Ogre::SceneNode*>(it.getNext());
            processNode(child, out, mStream);
        }

    }


    void VoxSceneDumper::dumpToObjFile(const std::string& filePath, Ogre::SceneNode* node){
        std::ofstream* mStream = new std::ofstream();
        mStream->open(filePath);

        VoxData out;
        processNode(node, out, mStream);

        //Write the values
        for(const VertexEntry& v : out.verts){
            *mStream << "v " << v.x << " " << v.y << " " << v.z
            << " " << v.r << " " << v.g << " " << v.b << "\n";
        }
        for(const VertexEntry& v : out.verts){
            *mStream << "vn " << v.xn << " " << v.yn << " " << v.zn << "\n";
        }

        assert(out.verts.size() % 4 == 0);
        size_t numFaces = out.verts.size() / 4;
        size_t current = 0;
        for(Ogre::uint32 i = 0; i < numFaces; i++){
            *mStream << "f " << 1 + current + 0 << "//" << 1 + current + 0
            << " " << 1 + current + 1 << "//" << 1 + current + 1
            << " " << 1 + current + 2 << "//" << 1 + current + 2
            << " " << 1 + current + 3 << "//" << 1 + current + 3 << "\n";

            current += 4;
        }

        delete mStream;
    }

}
