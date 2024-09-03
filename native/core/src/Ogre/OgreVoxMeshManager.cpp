#include "OgreStableHeaders.h"

#include "OgreVoxMeshManager.h"
#include "OgreVoxMesh.h"
#include "OgreMeshManager2.h"
#include "OgreMeshManager.h"

#include "OgreMesh2.h"
#include "OgreSubMesh2.h"
#include "OgreMatrix4.h"
#include "OgrePatchMesh.h"
#include "OgreException.h"

#include "OgrePrefabFactory.h"

namespace Ogre
{
    template<> VoxMeshManager* Singleton<VoxMeshManager>::msSingleton = 0;
    //-----------------------------------------------------------------------
    VoxMeshManager* VoxMeshManager::getSingletonPtr(void)
    {
        return msSingleton;
    }
    VoxMeshManager& VoxMeshManager::getSingleton(void)
    {
        assert( msSingleton );  return ( *msSingleton );
    }
    //-----------------------------------------------------------------------
    VoxMeshManager::VoxMeshManager() :
        mVaoManager( 0 ),
        mBoundsPaddingFactor( 0.01 )/*,
        mListener( 0 )*/
    {
        mLoadOrder = 300.0f;
        mResourceType = "VoxMesh";

        ResourceGroupManager::getSingleton()._registerResourceManager(mResourceType, this);
    }
    //-----------------------------------------------------------------------
    VoxMeshManager::~VoxMeshManager()
    {
        ResourceGroupManager::getSingleton()._unregisterResourceManager(mResourceType);
    }
    //-----------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::getByName(const String& name, const String& groupName)
    {
        return getResourceByName(name, groupName).staticCast<VoxMesh>();
    }
    //-----------------------------------------------------------------------
    void VoxMeshManager::_initialise(void)
    {
    }
    //-----------------------------------------------------------------------
    void VoxMeshManager::_setVaoManager( VaoManager *vaoManager )
    {
        mVaoManager = vaoManager;
    }
    //-----------------------------------------------------------------------
    VoxMeshManager::ResourceCreateOrRetrieveResult VoxMeshManager::createOrRetrieve(
        const String& name, const String& group,
        bool isManual, ManualResourceLoader* loader,
        const NameValuePairList* params,
        BufferType vertexBufferType,
        BufferType indexBufferType,
        bool vertexBufferShadowed, bool indexBufferShadowed)
    {
        ResourceCreateOrRetrieveResult res =
            ResourceManager::createOrRetrieve(name,group,isManual,loader,params);
        MeshPtr pMesh = res.first.staticCast<VoxMesh>();
        // Was it created?
        if (res.second)
        {
            pMesh->setVertexBufferPolicy(vertexBufferType, vertexBufferShadowed);
            pMesh->setIndexBufferPolicy(indexBufferType, indexBufferShadowed);
        }
        return res;

    }
    //-----------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::prepare( const String& filename, const String& groupName,
                                  BufferType vertexBufferType,
                                  BufferType indexBufferType,
                                  bool vertexBufferShadowed, bool indexBufferShadowed)
    {
        VoxMeshPtr pMesh = createOrRetrieve( filename, groupName, false, 0, 0,
                                          vertexBufferType, indexBufferType,
                                          vertexBufferShadowed, indexBufferShadowed ).
                        first.staticCast<VoxMesh>();
        pMesh->prepare();
        return pMesh;
    }
    //-----------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::load( const String& filename, const String& groupName,
                               BufferType vertexBufferType,
                               BufferType indexBufferType,
                               bool vertexBufferShadowed, bool indexBufferShadowed)
    {
        VoxMeshPtr pMesh = createOrRetrieve( filename, groupName, false, 0, 0,
                                          vertexBufferType, indexBufferType,
                                          vertexBufferShadowed, indexBufferShadowed ).
                        first.staticCast<VoxMesh>();
        pMesh->load();
        return pMesh;
    }
    //-----------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::create( const String& name, const String& group,
                                    bool isManual, ManualResourceLoader* loader,
                                    const NameValuePairList* createParams)
    {
        return createResource(name,group,isManual,loader,createParams).staticCast<VoxMesh>();
    }
    //-----------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::createManual( const String& name, const String& groupName,
                                       ManualResourceLoader* loader )
    {
        // Don't try to get existing, create should fail if already exists
        if( !this->getResourceByName( name, groupName ).isNull() )
        {
            OGRE_EXCEPT( Ogre::Exception::ERR_DUPLICATE_ITEM,
                         "v2 Mesh with name '" + name + "' already exists.",
                         "VoxMeshManager::createManual" );
        }
        return create(name, groupName, true, loader);
    }
    //-------------------------------------------------------------------------
    VoxMeshPtr VoxMeshManager::createByImportingV1( const String &name, const String &groupName,
                                              v1::Mesh *mesh, bool halfPos, bool halfTexCoords,
                                              bool qTangents, bool halfPose )
    {
        // Create manual mesh which calls back self to load
        VoxMeshPtr pMesh = createManual(name, groupName, this);
        // store parameters
        V1MeshImportParams params;
        params.name = mesh->getName();
        params.groupName = mesh->getGroup();
        params.halfPos = halfPos;
        params.halfTexCoords = halfTexCoords;
        params.qTangents = qTangents;
        params.halfPose = halfPose;
        mV1MeshImportParams[pMesh.getPointer()] = params;

        return pMesh;
    }
    //-------------------------------------------------------------------------
    void VoxMeshManager::loadResource(Resource* res)
    {
        Mesh* mesh = static_cast<Mesh*>(res);

        // Find build parameters
        V1MeshImportParamsMap::iterator it = mV1MeshImportParams.find(res);
        if (it == mV1MeshImportParams.end())
        {
            OGRE_EXCEPT(Exception::ERR_ITEM_NOT_FOUND,
                "Cannot find build parameters for " + res->getName(),
                "VoxMeshManager::loadResource");
        }
        V1MeshImportParams& params = it->second;

        Ogre::v1::MeshPtr meshV1 =
            Ogre::v1::MeshManager::getSingleton().getByName( params.name, params.groupName );

        bool unloadV1 = (meshV1->isReloadable() && meshV1->getLoadingState() == Resource::LOADSTATE_UNLOADED);

        mesh->importV1(meshV1.get(), params.halfPos, params.halfTexCoords, params.qTangents, params.halfPose);

        if(unloadV1)
            meshV1->unload();
    }
    //-------------------------------------------------------------------------
    /*void VoxMeshManager::setListener(MeshSerializerListener *listener)
    {
        mListener = listener;
    }
    //-------------------------------------------------------------------------
    MeshSerializerListener *VoxMeshManager::getListener()
    {
        return mListener;
    }*/
    //-----------------------------------------------------------------------
    Real VoxMeshManager::getBoundsPaddingFactor(void)
    {
        return mBoundsPaddingFactor;
    }
    //-----------------------------------------------------------------------
    void VoxMeshManager::setBoundsPaddingFactor(Real paddingFactor)
    {
        mBoundsPaddingFactor = paddingFactor;
    }
    //-----------------------------------------------------------------------
    Resource* VoxMeshManager::createImpl(const String& name, ResourceHandle handle,
        const String& group, bool isManual, ManualResourceLoader* loader,
        const NameValuePairList* createParams)
    {
        // no use for createParams here
        return OGRE_NEW VoxMesh(this, name, handle, group, mVaoManager, isManual, loader);
    }
    //-----------------------------------------------------------------------
}
