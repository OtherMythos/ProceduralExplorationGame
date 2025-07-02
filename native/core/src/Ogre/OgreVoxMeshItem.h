#pragma once

#include "Ogre.h"
#include "OgreItem.h"
#include "OgreSubItem.h"

namespace Ogre{

    class VoxMeshItem : public Item
    {
        friend class VoxMeshItemFactory;
    protected:
        VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager );
        VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager, const MeshPtr& mesh, Ogre::uint32 flags );

        void _initialise( bool forceReinitialise /*= false*/, bool bUseMeshMat /*= true */ );

        void buildSubItems( vector<String>::type *materialsList, bool bUseMeshMat /* = true*/ );

        const String& getMovableType(void) const;

        void loadingComplete(Resource* resource);

        Ogre::uint32 mFlags;
    };

    class VoxMeshItemFactory : public MovableObjectFactory
    {
    protected:
        virtual MovableObject* createInstanceImpl( IdType id, ObjectMemoryManager *objectMemoryManager,
                                                   SceneManager *manager,
                                                   const NameValuePairList* params = 0 );
    public:
        VoxMeshItemFactory() {}
        virtual ~VoxMeshItemFactory();

        static String FACTORY_TYPE_NAME;

        const String& getType(void) const;
        void destroyInstance( MovableObject* obj);

    };

    class VoxMeshSubItem : public SubItem
    {
    public:
        VoxMeshSubItem( Item *parent, SubMesh *subMeshBasis );
    };

}
