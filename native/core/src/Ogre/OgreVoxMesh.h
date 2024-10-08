#pragma once

#include "OgreMesh2.h"

namespace Ogre{

    class VoxMesh;

    typedef SharedPtr<VoxMesh> VoxMeshPtr;

    class VoxMesh : public Mesh{
    public:

        VoxMesh( ResourceManager* creator, const String& name, ResourceHandle handle, const String& group, VaoManager *vaoManager, bool isManual, ManualResourceLoader* loader);

        void loadImpl();
    };


}
