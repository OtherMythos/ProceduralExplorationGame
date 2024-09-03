#include "OgreVoxMesh.h"

#include "Ogre.h"
#include "OgreMeshManager2.h"
#include "OgreMesh2Serializer.h"
#include "OgreProfiler.h"
#include "OgreVoxMeshSerializer.h"

namespace Ogre{

    VoxMesh::VoxMesh(ResourceManager* creator, const String& name, ResourceHandle handle, const String& group, VaoManager *vaoManager, bool isManual = false, ManualResourceLoader* loader = 0)
        : Mesh(creator, name, handle, group, vaoManager, isManual, loader)
    {

    }

    void VoxMesh::loadImpl()
    {
        OgreProfileExhaustive( "VoxMesh::loadImpl" );

        VoxMeshSerializer voxSerializer( mVaoManager );
        //MeshSerializer serializer( mVaoManager );
        //serializer.setListener(MeshManager::getSingleton().getListener());

        // If the only copy is local on the stack, it will be cleaned
        // up reliably in case of exceptions, etc
        DataStreamPtr data(mFreshFromDisk);
        mFreshFromDisk.setNull();

        if (data.isNull()) {
            OGRE_EXCEPT(Exception::ERR_INVALID_STATE,
                        "Data doesn't appear to have been prepared in " + mName,
                        "Mesh::loadImpl()");
        }

        voxSerializer.importMesh(data, this);
        //serializer.importMesh(data, this);

        if( mHashForCaches[0] == 0u && mHashForCaches[1] == 0u && Mesh::msUseTimestampAsHash )
        {
            try
            {
                LogManager::getSingleton().logMessage( "Using timestamp as hash cache for Mesh " + mName,
                                                       LML_TRIVIAL );
                Archive *archive =
                    ResourceGroupManager::getSingleton()._getArchiveToResource( mName, mGroup, true );
                mHashForCaches[0] = static_cast<uint64>( archive->getModifiedTime( mName ) );
            }
            catch( Exception & )
            {
                LogManager::getSingleton().logMessage( "Using timestamp as hash cache for Mesh " + mName,
                                                       LML_TRIVIAL );
            }
        }
    }

}
