#include "OgreVoxMeshItem.h"

#include "OgreItem.h"
#include "OgreMeshManager2.h"
#include "OgreVoxMesh.h"
#include "OgreVoxMeshManager.h"

namespace Ogre{

    VoxMeshItem::VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager )
        : Item( id, objectMemoryManager, manager )
    {
    }
    VoxMeshItem::VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager, const MeshPtr& mesh )
        : Item( id, objectMemoryManager, manager, mesh )
    {

    }

    const String& VoxMeshItem::getMovableType(void) const
    {
        return VoxMeshItemFactory::FACTORY_TYPE_NAME;
    }


    String VoxMeshItemFactory::FACTORY_TYPE_NAME = "VoxMeshItem";

    const String& VoxMeshItemFactory::getType(void) const{
        return FACTORY_TYPE_NAME;
    }

    MovableObject* VoxMeshItemFactory::createInstanceImpl( IdType id,
                                                    ObjectMemoryManager *objectMemoryManager,
                                                    SceneManager *manager,
                                                    const NameValuePairList* params )
    {
        // must have mesh parameter
        VoxMeshPtr pMesh;
        if (params != 0)
        {
            String groupName = ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME;

            NameValuePairList::const_iterator ni;

            ni = params->find("resourceGroup");
            if (ni != params->end())
            {
                groupName = ni->second;
            }

            ni = params->find("mesh");
            if (ni != params->end())
            {
                // Get mesh (load if required)
                //pMesh = MeshManager::getSingleton().load( ni->second, groupName );
                pMesh = VoxMeshManager::getSingleton().load( ni->second, groupName );
            }

        }
        if (pMesh.isNull())
        {
            OGRE_EXCEPT(Exception::ERR_INVALIDPARAMS,
                "'mesh' parameter required when constructing a VoxMeshItem.",
                "VoxMeshItemFactory::createInstance");
        }

        return OGRE_NEW VoxMeshItem( id, objectMemoryManager, manager, pMesh );
    }

    void VoxMeshItemFactory::destroyInstance( MovableObject* obj)
    {
        OGRE_DELETE obj;
    }

}
