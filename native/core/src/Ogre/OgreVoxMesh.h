#pragma once

#define _ALLOW_KEYWORD_MACROS
#define final
#include "OgreMesh2.h"
#undef final
#undef _ALLOW_KEYWORD_MACROS

namespace Ogre{

    class VoxMesh;

    typedef SharedPtr<VoxMesh> VoxMeshPtr;

    class VoxMesh : public Mesh{
    public:

        VoxMesh( ResourceManager* creator, const String& name, ResourceHandle handle, const String& group, VaoManager *vaoManager, bool isManual, ManualResourceLoader* loader);

        void loadImpl();
    };


}
