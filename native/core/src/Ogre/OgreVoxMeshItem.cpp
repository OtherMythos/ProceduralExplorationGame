#include "OgreVoxMeshItem.h"

#include "OgreMeshManager2.h"
#include "OgreVoxMesh.h"
#include "OgreVoxMeshManager.h"
#include "OgreSubMesh2.h"

#include "GamePrerequisites.h"
//TODO move this somewhere else
#include "MapGen/BaseClient/MapGenBaseClientPrerequisites.h"

namespace Ogre{

    VoxMeshItem::VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager )
        : Item( id, objectMemoryManager, manager )
    {
    }
    VoxMeshItem::VoxMeshItem( IdType id, ObjectMemoryManager *objectMemoryManager, SceneManager *manager, const MeshPtr& mesh, Ogre::uint32 flags )
        : Item( id, objectMemoryManager, manager ),
        mFlags(flags)
    {
        mMesh = mesh;
        _initialise(false, true);
    }

    const String& VoxMeshItem::getMovableType(void) const
    {
        return VoxMeshItemFactory::FACTORY_TYPE_NAME;
    }

    void VoxMeshItem::loadingComplete(Resource* resource){
        Ogre::Item::loadingComplete(resource);
    }



    void VoxMeshItem::_initialise( bool forceReinitialise /*= false*/, bool bUseMeshMat /*= true */ )
    {
        vector<String>::type prevMaterialsList;
        if( forceReinitialise )
        {
            if( mMesh->getNumSubMeshes() == mSubItems.size() )
            {
                for( SubItem &subitem : mSubItems )
                    prevMaterialsList.push_back( subitem.getDatablockOrMaterialName() );
            }
            _deinitialise();
        }

        if( mInitialised )
            return;

        // register for a callback when mesh is finished loading
        mMesh->addListener( this );

        // On-demand load
        mMesh->load();
        // If loading failed, or deferred loading isn't done yet, defer
        // Will get a callback in the case of deferred loading
        // Skeletons are cascade-loaded so no issues there
        if( !mMesh->isLoaded() )
            return;

        // Is mesh skeletally animated?
        if( mMesh->hasSkeleton() && mMesh->getSkeleton() && mManager )
        {
            const SkeletonDef *skeletonDef = mMesh->getSkeleton().get();
            mSkeletonInstance = mManager->createSkeletonInstance( skeletonDef );
        }

        mLodMesh = mMesh->_getLodValueArray();

        // Build main subItem list
        buildSubItems( prevMaterialsList.empty() ? 0 : &prevMaterialsList, bUseMeshMat );

        {
            // Without filling the renderables list, the RenderQueue won't
            // catch our sub entities and thus we won't be rendered
            mRenderables.reserve( mSubItems.size() );
            for( SubItem &subitem : mSubItems )
                mRenderables.push_back( &subitem );
        }

        Aabb aabb( mMesh->getAabb() );
        mObjectData.mLocalAabb->setFromAabb( aabb, mObjectData.mIndex );
        mObjectData.mWorldAabb->setFromAabb( aabb, mObjectData.mIndex );
        mObjectData.mLocalRadius[mObjectData.mIndex] = aabb.getRadius();
        mObjectData.mWorldRadius[mObjectData.mIndex] = aabb.getRadius();
        if( mParentNode )
        {
            updateSingleWorldAabb();
            updateSingleWorldRadius();
        }

        mInitialised = true;
    }

    void VoxMeshItem::buildSubItems( vector<String>::type *materialsList, bool bUseMeshMat /* = true*/ )
    {
        // Create SubEntities
        unsigned numSubMeshes = mMesh->getNumSubMeshes();
        mSubItems.reserve( numSubMeshes );
        const Ogre::String defaultDatablock;
        for( unsigned i = 0; i < numSubMeshes; ++i )
        {
            SubMesh *subMesh = mMesh->getSubMesh( i );
            mSubItems.push_back( VoxMeshSubItem( this, subMesh ) );

            // Try first Hlms materials, then the low level ones.

            Ogre::Vector4 vals = Ogre::Vector4::ZERO;
            vals.x = *reinterpret_cast<Ogre::Real*>(&mFlags);
            mSubItems.back().setCustomParameter(0, vals);

            mSubItems.back().setDatablockOrMaterialName( "baseVoxelMaterial", mMesh->getGroup() );
        }
    }



    VoxMeshSubItem::VoxMeshSubItem( Item *parent, SubMesh *subMeshBasis )
        : SubItem(parent, subMeshBasis) {

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
        Ogre::uint32 flags =
            ProceduralExplorationGameCore::HLMS_PACKED_VOXELS |
            ProceduralExplorationGameCore::HLMS_PACKED_OFFLINE_VOXELS;
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

            ni = params->find("flags");
            if (ni != params->end()){
                flags = Ogre::StringConverter::parseUnsignedInt(ni->second);
            }

        }
        if (pMesh.isNull())
        {
            OGRE_EXCEPT(Exception::ERR_INVALIDPARAMS,
                "'mesh' parameter required when constructing a VoxMeshItem.",
                "VoxMeshItemFactory::createInstance");
        }

        return OGRE_NEW VoxMeshItem( id, objectMemoryManager, manager, pMesh, flags );
    }

    void VoxMeshItemFactory::destroyInstance( MovableObject* obj)
    {
        OGRE_DELETE obj;
    }

}
