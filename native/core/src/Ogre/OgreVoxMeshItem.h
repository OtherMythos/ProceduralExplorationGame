#pragma once

#include "Ogre.h"
#include "OgreItem.h"

namespace Ogre{

    class VoxMeshItem : public Item
    {
        friend class VoxMeshItemFactory;
    protected:
        VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager );
        VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager, const MeshPtr& mesh );

        const String& getMovableType(void) const;
    };

    class VoxMeshItemFactory : public MovableObjectFactory
    {
    protected:
        virtual MovableObject* createInstanceImpl( IdType id, ObjectMemoryManager *objectMemoryManager,
                                                   SceneManager *manager,
                                                   const NameValuePairList* params = 0 );
    public:
        VoxMeshItemFactory() {}
        ~VoxMeshItemFactory() {}

        static String FACTORY_TYPE_NAME;

        const String& getType(void) const;
        void destroyInstance( MovableObject* obj);

    };

}
