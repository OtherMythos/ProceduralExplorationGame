//Some compositor scenes are generic.
//Giving them a designated type allows for things like easy access to cameras and queries.
enum CompositorSceneType{
    NONE,
    COMBAT,
    COMBAT_PLAYER,
    EXPLORATION,
    WORLD_SCENE

    MAX
};

::CompositorManager <- {
    mRenderWindowWorkspace_ = null

    mActiveCompositors_ = []
    mTotalCompositors_ = 0
    mCompositorsForTypes = array(CompositorSceneType.MAX, null)

    CompositorDef = class{
        mWorkspace = null;
        mTexture = null;
        mDatablock = null;
        mType = CompositorSceneType.NONE;
        mCamera = null;

        constructor(workspace, texture, datablock, compType, camera){
            mWorkspace = workspace;
            mTexture = texture;
            mDatablock = datablock;
            mType = compType;
            mCamera = camera;
        }

        function destroy(){
            _compositor.removeWorkspace(mWorkspace);
            _hlms.destroyDatablock(mDatablock);
            _graphics.destroyTexture(mTexture);
        }
    }

    function setup(){
        mRenderWindowWorkspace_ = _compositor.addWorkspace([_window.getRenderTexture()], _camera.getCamera(), "renderWindowWorkspace", true);
    }

    function createCompositorWorkspace(workspaceName, size, compositorSceneType){
        local newTex = _graphics.createTexture("compositor/renderTexture" + mTotalCompositors_);
        newTex.setResolution(size.x.tointeger(), size.y.tointeger());
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        local newCamera = _scene.createCamera("compositor/camera" + mTotalCompositors_);
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);

        local newWorkspace = _compositor.addWorkspace([newTex], newCamera, workspaceName, true);

        local datablock = _hlms.unlit.createDatablock("renderTextureDatablock" + mTotalCompositors_);
        datablock.setTexture(0, newTex);

        local compDef = CompositorDef(newWorkspace, newTex, datablock, compositorSceneType, newCamera);
        local id = registerNewCompositor_(compDef, compositorSceneType);

        //Add some uniqueness to the names.
        mTotalCompositors_++;

        print("Added compositor with id " + id)

        return id;
    }

    function destroyCompositorWorkspace(workspaceId){
        local data = mActiveCompositors_[workspaceId];
        mCompositorsForTypes[data.mType] = null;
        data.destroy();
        mActiveCompositors_[workspaceId] = null;
    }

    function getCameraForSceneType(sceneType){
        local data = mCompositorsForTypes[sceneType];
        return data == null ? null : data.mCamera;
    }

    function getDatablockForCompositor(id){
        return mActiveCompositors_[id].mDatablock;
    }

    function registerNewCompositor_(newWorkspace, sceneType){
        mCompositorsForTypes[sceneType] = newWorkspace;

        local idx = mActiveCompositors_.find(null);
        if(idx == null){
            local id = mActiveCompositors_.len();
            mActiveCompositors_.append(newWorkspace);
            return id;
        }

        mActiveCompositors_[idx] = newWorkspace;
        return idx;
    }
};
