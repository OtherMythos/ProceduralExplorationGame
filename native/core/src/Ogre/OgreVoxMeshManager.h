#pragma once

#include "OgrePrerequisites.h"

#include "OgreVoxMesh.h"

#include "OgreResourceManager.h"
#include "OgreSingleton.h"
#include "OgreVector3.h"
#include "Vao/OgreBufferPacked.h"
#include "OgreHeaderPrefix.h"

namespace Ogre
{
    class VoxMeshManager: public ResourceManager, public Singleton<VoxMeshManager>,
        public ManualResourceLoader
    {
    protected:
        /// @copydoc ResourceManager::createImpl
        Resource* createImpl(const String& name, ResourceHandle handle,
            const String& group, bool isManual, ManualResourceLoader* loader,
            const NameValuePairList* createParams);

        VaoManager *mVaoManager;

        //the factor by which the bounding box of an entity is padded
        Real mBoundsPaddingFactor;

        // The listener to pass to serializers
        //MeshSerializerListener *mListener;

    public:
        VoxMeshManager();
        ~VoxMeshManager();

        /** Initialises the manager, only to be called by OGRE internally. */
        void _initialise(void);
        void _setVaoManager( VaoManager *vaoManager );

        /// Get a resource by name
        /// @see ResourceManager::getResourceByName
        VoxMeshPtr getByName(const String& name, const String& groupName = ResourceGroupManager::AUTODETECT_RESOURCE_GROUP_NAME);


        /// Create a new mesh
        /// @see ResourceManager::createResource
        VoxMeshPtr create (const String& name, const String& group,
                            bool isManual = false, ManualResourceLoader* loader = 0,
                            const NameValuePairList* createParams = 0);

#if OGRE_COMPILER == OGRE_COMPILER_CLANG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Woverloaded-virtual"
#endif

        /** Create a new mesh, or retrieve an existing one with the same
            name if it already exists.
            @param vertexBufferUsage The usage flags with which the vertex buffer(s)
                will be created
            @param indexBufferUsage The usage flags with which the index buffer(s) created for
                this mesh will be created with.
            @param vertexBufferShadowed If true, the vertex buffers will be shadowed by system memory
                copies for faster read access
            @param indexBufferShadowed If true, the index buffers will be shadowed by system memory
                copies for faster read access
        @see ResourceManager::createOrRetrieve
        */
        ResourceCreateOrRetrieveResult createOrRetrieve(const String& name,
            const String& group,
            bool isManual=false, ManualResourceLoader* loader=0,
            const NameValuePairList* params=0,
            BufferType vertexBufferType = BT_IMMUTABLE,
            BufferType indexBufferType = BT_IMMUTABLE,
            bool vertexBufferShadowed = true, bool indexBufferShadowed = true);

        /** Prepares a mesh for loading from a file.  This does the IO in advance of the call to load().
            @note
                If the model has already been created (prepared or loaded), the existing instance
                will be returned.
            @remarks
                Ogre loads model files from it's own proprietary
                format called .mesh. This is because having a single file
                format is better for runtime performance, and we also have
                control over pre-processed data (such as
                collision boxes, LOD reductions etc).
            @param filename The name of the .mesh file
            @param groupName The name of the resource group to assign the mesh to
            @param vertexBufferUsage The usage flags with which the vertex buffer(s)
                will be created
            @param indexBufferUsage The usage flags with which the index buffer(s) created for
                this mesh will be created with.
            @param vertexBufferShadowed If true, the vertex buffers will be shadowed by system memory
                copies for faster read access
            @param indexBufferShadowed If true, the index buffers will be shadowed by system memory
                copies for faster read access
        */
        VoxMeshPtr prepare( const String& filename, const String& groupName,
                         BufferType vertexBufferType = BT_IMMUTABLE,
                         BufferType indexBufferType = BT_IMMUTABLE,
                         bool vertexBufferShadowed = true, bool indexBufferShadowed = true );

        /** Loads a mesh from a file, making it immediately available for use.
            @note
                If the model has already been created (prepared or loaded), the existing instance
                will be returned.
            @remarks
                Ogre loads model files from it's own proprietary
                format called .mesh. This is because having a single file
                format is better for runtime performance, and we also have
                control over pre-processed data (such as
                collision boxes, LOD reductions etc).
            @param filename The name of the .mesh file
            @param groupName The name of the resource group to assign the mesh to
            @param vertexBufferUsage The usage flags with which the vertex buffer(s)
                will be created
            @param indexBufferUsage The usage flags with which the index buffer(s) created for
                this mesh will be created with.
            @param vertexBufferShadowed If true, the vertex buffers will be shadowed by system memory
                copies for faster read access
            @param indexBufferShadowed If true, the index buffers will be shadowed by system memory
                copies for faster read access
        */
        VoxMeshPtr load( const String& filename, const String& groupName,
                      BufferType vertexBufferType = BT_IMMUTABLE,
                      BufferType indexBufferType = BT_IMMUTABLE,
                      bool vertexBufferShadowed = true, bool indexBufferShadowed = true );

#if OGRE_COMPILER == OGRE_COMPILER_CLANG
#pragma clang diagnostic pop
#endif

        /** Creates a new Mesh specifically for manual definition rather
            than loading from an object file.
        @remarks
            Note that once you've defined your mesh, you must call Mesh::_setBounds and
            Mesh::_setBoundingRadius in order to define the bounds of your mesh. In previous
            versions of OGRE you could call Mesh::_updateBounds, but OGRE's support of
            write-only vertex buffers makes this no longer appropriate.
        @param name The name to give the new mesh
        @param groupName The name of the resource group to assign the mesh to
        @param loader ManualResourceLoader which will be called to load this mesh
            when the time comes. It is recommended that you populate this field
            in order that the mesh can be rebuilt should the need arise
        */
        VoxMeshPtr createManual( const String& name, const String& groupName,
            ManualResourceLoader* loader = 0);

        /** Imports a v1 mesh to new mesh, with optional optimization conversions.
        @remarks
            The vertex stream will be converted to a single interleaved buffer; i.e.
            if the original mesh had 3 vertex buffers:
                [1] = POSITION, POSITION, POSITION, POSITION, ...
                [2] = NORMALS, NORMALS, NORMALS, NORMALS, ...
                [3] = UV, UV, UV, UV, ...
            then the v2 mesh will have only 1 vertex buffer:
                [1] = POSITION NORMALS UV, POS NORM UV, POS NORM UV, POS NORM UV, ...
            Resulting mesh is reloadable as long as original mesh exists and is reloadable.
        @param name The name to give the new mesh
        @param groupName The name of the resource group to assign the mesh to
        @param mesh
            The source v1 mesh to convert from. You can unload but should not delete
            this pointer if you want to be able to reload the converted mesh.
        @param halfPos
            True if you want to convert the position data to VET_HALF4 format.
            Recommended on desktop to reduce memory and bandwidth requirements.
            Rarely the extra precision is needed.
            Unfortuntately on mobile, not all ES2 devices support VET_HALF4.
        @param halfTexCoords
            True if you want to convert the position data to VET_HALF2 or VET_HALF4 format.
            Same recommendations as halfPos.
        @param qTangents
            True if you want to generate tangent and reflection information (modifying
            the original v1 mesh) and convert this data to a QTangent, requiring
            VET_SHORT4_SNORM (8 bytes vs 28 bytes to store normals, tangents and
            reflection). Needs much less space, trading for more ALU ops in the
            vertex shader for decoding the QTangent.
            Highly recommended on both desktop and mobile if you need tangents (i.e.
            normal mapping).
        @param halfPose
            True if you want the pose buffer to have pixel format PF_FLOAT16_RGBA
            which uses significantly less memory. Otherwise it is created with pixel
            format PF_FLOAT32_RGBA. Rarely the extra precision is needed.
        */
        VoxMeshPtr createByImportingV1( const String& name, const String& groupName,
            v1::Mesh* mesh, bool halfPos, bool halfTexCoords, bool qTangents, bool halfPose = true);

        /** Override standard Singleton retrieval.
        @remarks
        Why do we do this? Well, it's because the Singleton
        implementation is in a .h file, which means it gets compiled
        into anybody who includes it. This is needed for the
        Singleton template to work, but we actually only want it
        compiled into the implementation of the class based on the
        Singleton, not all of them. If we don't change this, we get
        link errors when trying to use the Singleton-based class from
        an outside dll.
        @par
        This method just delegates to the template version anyway,
        but the implementation stays in this single compilation unit,
        preventing link errors.
        */
        static VoxMeshManager& getSingleton(void);
        /** Override standard Singleton retrieval.
        @remarks
        Why do we do this? Well, it's because the Singleton
        implementation is in a .h file, which means it gets compiled
        into anybody who includes it. This is needed for the
        Singleton template to work, but we actually only want it
        compiled into the implementation of the class based on the
        Singleton, not all of them. If we don't change this, we get
        link errors when trying to use the Singleton-based class from
        an outside dll.
        @par
        This method just delegates to the template version anyway,
        but the implementation stays in this single compilation unit,
        preventing link errors.
        */
        static VoxMeshManager* getSingletonPtr(void);

        /** Gets the factor by which the bounding box of an entity is padded.
            Default is 0.01
        */
        Real getBoundsPaddingFactor(void);

        /** Sets the factor by which the bounding box of an entity is padded
        */
        void setBoundsPaddingFactor(Real paddingFactor);

        /** Sets the listener used to control mesh loading through the serializer.
        */
        //void setListener(MeshSerializerListener *listener);

        /** Gets the listener used to control mesh loading through the serializer.
        */
        //MeshSerializerListener *getListener();

        /** @see ManualResourceLoader::loadResource */
        void loadResource(Resource* res);

    protected:
        /** Saved parameters used to (re)build a manual mesh built by this class */
        struct V1MeshImportParams
        {
            String name, groupName;
            bool halfPos, halfTexCoords, qTangents, halfPose;
        };
        /** Map from resource pointer to parameter set */
        typedef map<Resource*, V1MeshImportParams>::type V1MeshImportParamsMap;
        V1MeshImportParamsMap mV1MeshImportParams;
    };

    /** @} */
    /** @} */

} //namespace

#include "OgreHeaderSuffix.h"
