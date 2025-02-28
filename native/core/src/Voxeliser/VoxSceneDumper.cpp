#include "VoxSceneDumper.h"

#include "Ogre.h"
#include "OgreItem.h"
#include "OgreMesh2.h"
#include "OgreSubMesh2.h"
#include "Vao/OgreVaoManager.h"
#include "Vao/OgreAsyncTicket.h"

#include <cstring>
#include <fstream>
#include <iostream>

namespace ProceduralExplorationGameCore{

    VoxSceneDumper::VoxSceneDumper(){

    }

    VoxSceneDumper::~VoxSceneDumper(){

    }

    struct VertexEntry{
        float x, y, z, r, g, b;
    };
    struct FaceEntry{
        size_t a, b, c;
    };
    struct VoxData{
        std::vector<VertexEntry> verts;
        std::vector<FaceEntry> faces;
    };

    void processObject(Ogre::MovableObject* obj, const Ogre::Matrix4& worldTransform, VoxData& out){
        const std::string movType = obj->getMovableType();
        if(movType == "VoxMeshItem"){
            Ogre::Item* item = dynamic_cast<Ogre::Item*>(obj);
            for(size_t i = 0; i < item->getMesh()->getNumSubMeshes(); i++){
                Ogre::SubMesh* subMesh = item->getMesh()->getSubMesh(i);

                Ogre::VertexArrayObjectArray vaos = subMesh->mVao[Ogre::VpNormal];

                for (auto vao : vaos) {
                    Ogre::VertexBufferPacked* vBuf = vao->getVertexBuffers()[0];
                    Ogre::IndexBufferPacked* iBuf = vao->getIndexBuffer();

                    if (!vBuf || !iBuf) continue;

                    Ogre::VertexElement2Vec elements = vBuf->getVertexElements();
                    size_t vertexCount = vBuf->getNumElements();

                    //float* vertexData = static_cast<float*>(vBuf->map(Ogre::AOS_READ));
                    //uint16_t* indexData = static_cast<uint16_t*>(iBuf->map(Ogre::AOS_READ));

                    Ogre::AsyncTicketPtr ticketPtr = vBuf->readRequest(0, vertexCount);
                    const float * RESTRICT_ALIAS vertexData = reinterpret_cast<const float*RESTRICT_ALIAS>(ticketPtr->map());
                    Ogre::AsyncTicketPtr indiceTicketPtr = iBuf->readRequest(0, iBuf->getNumElements());
                    const uint16_t* indexData = static_cast<const uint16_t*>(indiceTicketPtr->map());

                    //float * RESTRICT_ALIAS vertexData = reinterpret_cast<float*RESTRICT_ALIAS>(
                    //            vBuf->map( 0, vertexCount ) );
                    //uint16_t* indexData = static_cast<uint16_t*>(iBuf->map(0, iBuf->getNumElements() ));

                    size_t cc = 0;
                    for (size_t v = 0; v < vertexCount; ++v) {
                        Ogre::Vector3 position, normal;
                        Ogre::Vector2 uv;

                        for (const auto& elem : elements) {
                            //float* ptr = vertexData + elem.mOffset / sizeof(float) + v * vBuf->getVertexSize() / sizeof(float);
                            const float* ptr = vertexData + (cc * 8 * sizeof(float));
                            switch (elem.mSemantic) {
                                case Ogre::VES_POSITION:
                                    position = worldTransform * Ogre::Vector3(ptr[0], ptr[1], ptr[2]);
                                    //vertices.push_back(position);
                                    break;
                                case Ogre::VES_NORMAL:
                                    //normal = Ogre::Matrix3(worldTransform) * Ogre::Vector3(ptr[0], ptr[1], ptr[2]);
                                    //normals.push_back(normal);
                                    break;
                                case Ogre::VES_TEXTURE_COORDINATES:
                                    uv = Ogre::Vector2(ptr[0], ptr[1]);
                                    //uvs.push_back(uv);
                                    break;
                                default:
                                    break;
                            }
                        }
                        cc++;
                    }

                }
            }
            out.verts.push_back({0, 0, 0, 0, 0, 0});
        }
    }

    void processNode(Ogre::SceneNode* node, VoxData& out){
        const Ogre::Matrix4 transform = node->_getFullTransformUpdated();

        auto objIt = node->getAttachedObjectIterator();
        while(objIt.hasMoreElements()){
            Ogre::MovableObject* obj = objIt.getNext();

            processObject(obj, transform, out);
        }

        auto it = node->getChildIterator();
        while(it.hasMoreElements()){
            Ogre::SceneNode* child = dynamic_cast<Ogre::SceneNode*>(it.getNext());
            processNode(child, out);
        }
    }

/*
void writeSceneNodeToObj(Ogre::SceneNode* node, const std::string& filename) {
    std::ofstream objFile(filename);
    if (!objFile.is_open()) {
        std::cerr << "Failed to open file: " << filename << std::endl;
        return;
    }

    objFile << "# Exported from Ogre-Next 2.3\n";

    std::vector<Ogre::Vector3> vertices;
    std::vector<Ogre::Vector3> normals;
    std::vector<Ogre::Vector2> uvs;
    std::vector<int> indices;

    int vertexOffset = 1; // OBJ index starts at 1

    std::function<void(Ogre::SceneNode*, Ogre::Matrix4)> processNode;
    processNode = [&](Ogre::SceneNode* node, Ogre::Matrix4 parentTransform) {
        Ogre::Matrix4 worldTransform = parentTransform * node->_getFullTransform();

        for (auto obj : node->getAttachedObjects()) {
            if (auto item = dynamic_cast<Ogre::Item*>(obj)) {
                Ogre::MeshPtr mesh = item->getMesh();
                for (size_t i = 0; i < mesh->getNumSubMeshes(); ++i) {
                    Ogre::SubMesh* subMesh = mesh->getSubMesh(i);
                    Ogre::VertexArrayObjectArray vaos = subMesh->mVao[Ogre::VpNormal];

                    for (auto vao : vaos) {
                        const Ogre::VertexBufferPacked* vBuf = vao->getVertexBuffer(0);
                        const Ogre::IndexBufferPacked* iBuf = vao->getIndexBuffer();

                        if (!vBuf || !iBuf) continue;

                        Ogre::VertexElement2Vec elements = vBuf->getVertexElements();
                        size_t vertexCount = vBuf->getNumElements();

                        float* vertexData = static_cast<float*>(vBuf->map(Ogre::AOS_READ));
                        uint16_t* indexData = static_cast<uint16_t*>(iBuf->map(Ogre::AOS_READ));

                        for (size_t v = 0; v < vertexCount; ++v) {
                            Ogre::Vector3 position, normal;
                            Ogre::Vector2 uv;

                            for (const auto& elem : elements) {
                                float* ptr = vertexData + elem.mOffset / sizeof(float) + v * vBuf->getVertexSize() / sizeof(float);
                                switch (elem.mSemantic) {
                                    case Ogre::VES_POSITION:
                                        position = worldTransform * Ogre::Vector3(ptr[0], ptr[1], ptr[2]);
                                        vertices.push_back(position);
                                        break;
                                    case Ogre::VES_NORMAL:
                                        normal = Ogre::Matrix3(worldTransform) * Ogre::Vector3(ptr[0], ptr[1], ptr[2]);
                                        normals.push_back(normal);
                                        break;
                                    case Ogre::VES_TEXTURE_COORDINATES:
                                        uv = Ogre::Vector2(ptr[0], ptr[1]);
                                        uvs.push_back(uv);
                                        break;
                                    default:
                                        break;
                                }
                            }
                        }

                        size_t indexCount = iBuf->getNumElements();
                        for (size_t i = 0; i < indexCount; i += 3) {
                            indices.push_back(vertexOffset + indexData[i]);
                            indices.push_back(vertexOffset + indexData[i + 1]);
                            indices.push_back(vertexOffset + indexData[i + 2]);
                        }

                        vertexOffset += vertexCount;
                        vBuf->unmap(Ogre::UO_UNMAP_ALL);
                        iBuf->unmap(Ogre::UO_UNMAP_ALL);
                    }
                }
            }
        }

        for (auto child : node->getChildren()) {
            if (auto childNode = dynamic_cast<Ogre::SceneNode*>(child)) {
                processNode(childNode, worldTransform);
            }
        }
    };

    processNode(node, Ogre::Matrix4::IDENTITY);

    for (const auto& v : vertices)
        objFile << "v " << v.x << " " << v.y << " " << v.z << "\n";
    for (const auto& n : normals)
        objFile << "vn " << n.x << " " << n.y << " " << n.z << "\n";
    for (const auto& uv : uvs)
        objFile << "vt " << uv.x << " " << uv.y << "\n";

    for (size_t i = 0; i < indices.size(); i += 3)
        objFile << "f " << indices[i] << "/" << indices[i] << "/" << indices[i]
                << " " << indices[i + 1] << "/" << indices[i + 1] << "/" << indices[i + 1]
                << " " << indices[i + 2] << "/" << indices[i + 2] << "/" << indices[i + 2] << "\n";

    objFile.close();
}
 */


    void VoxSceneDumper::dumpToObjFile(const std::string& filePath, Ogre::SceneNode* node){
        std::ofstream* mStream = new std::ofstream();
        mStream->open(filePath);

        VoxData out;
        processNode(node, out);

        for(size_t i = 0; i < 100; i++){
            const std::string test = "something";
            //mStream->write(test.c_str(), test.length());
            *mStream << "v" << "0" << std::endl;
        }

        delete mStream;

        //writeSceneNodeToObj(node, filePath);
    }

}
