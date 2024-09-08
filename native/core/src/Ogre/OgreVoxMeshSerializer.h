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

        uint8* readVertexBuffer(DataStreamPtr& stream, Mesh* pMesh, size_t* outVerts);
        void readBoundsInfo(DataStreamPtr& stream, Ogre::Aabb& outAABB, float& outRadius);

    };

}
