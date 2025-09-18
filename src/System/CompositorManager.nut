//Some compositor scenes are generic.
//Giving them a designated type allows for things like easy access to cameras and queries.
enum CompositorSceneType{
    EXPLORATION,
    INVENTORY_PLAYER_INSPECTOR,
    OVERWORLD,

    MAX,
    NONE
};

::CompositorManager <- {
    mRenderWindowWorkspace_ = null

    mActiveCompositors_ = []
    mTotalCompositors_ = 0
    mCompositorsForTypes = array(CompositorSceneType.MAX, null)
    mTextures_ = []

    mEffectCam = null
    mExplorationCamera = null

    mGameplayActive_ = false

    CompositorDef = class{
        mWorkspace = null;
        mTexture = null;
        mDatablock = null;
        mType = CompositorSceneType.NONE;
        mCamera = null;
        mName = null;

        constructor(workspace, texture, datablock, compType, camera, name){
            mWorkspace = workspace;
            mTexture = texture;
            mDatablock = datablock;
            mType = compType;
            mCamera = camera;
            mName = name;
        }

        function destroy(){
            _compositor.removeWorkspace(mWorkspace);
            _hlms.destroyDatablock(mDatablock);
            //_graphics.destroyTexture(mTexture);
        }
    }

    function setup(){
        for(local i = 0; i < CompositorSceneType.MAX; i++){
            local newTex = _graphics.createTexture("compositor/renderTexture" + i);
            newTex.setResolution(100, 100);
            newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
            mTextures_.append(newTex);
        }

        mExplorationCamera = _scene.createCamera("explorationCamera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(mExplorationCamera);

        mEffectCam = _scene.createCamera("compositor/foregroundEffectCamera");
        cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(mEffectCam);

        cameraNode.setPosition(0, 0, EFFECT_WINDOW_CAMERA_Z);
        mEffectCam.lookAt(0, 0, 0);
        mEffectCam.setAspectRatio(_window.getWidth().tofloat() / _window.getHeight().tofloat());
        mEffectCam.setProjectionType(_PT_ORTHOGRAPHIC);
        mEffectCam.setOrthoWindow(20, 20);

        ::FGEffectCamera <- mEffectCam;

        setGameplayActive(false);
    }

    function setGameplayActive(active){
        mGameplayActive_ = active;
        refreshRenderWindowWorkspace_();
    }

    function refreshRenderWindowWorkspace_(){
        if(mRenderWindowWorkspace_ != null){
            _compositor.removeWorkspace(mRenderWindowWorkspace_);
        }
        local textures = [_window.getRenderTexture()];
        foreach(i in mTextures_){
            textures.append(i);
        }
        local targetWorkspace = mGameplayActive_ ? "renderWindowWorkspaceGameplay" : "renderWindowWorkspace";
        mRenderWindowWorkspace_ = _compositor.addWorkspace(textures, _camera.getCamera(), targetWorkspace, true);
    }

    function createCompositorWorkspace(workspaceName, size, compositorSceneType, pointSampler=false){
        //local newTex = _graphics.createTexture("compositor/renderTexture" + mTotalCompositors_);
        local newTex = mTextures_[compositorSceneType];
        //newTex.waitForData();
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_ON_STORAGE);
        //newTex.waitForData();
        newTex.setResolution(size.x.tointeger(), size.y.tointeger());
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        local newCamera = _scene.createCamera("compositor/camera" + mTotalCompositors_);
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);

        local newWorkspace = _compositor.addWorkspace([newTex], newCamera, workspaceName, true);

        local blendBlock = _hlms.getBlendblock({
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA
        });
        local datablock = _hlms.unlit.createDatablock("renderTextureDatablock" + mTotalCompositors_, blendBlock);
        if(pointSampler){
            local sampler = _hlms.getSamplerblock({
                "mag": "point"
            });
            datablock.setTexture(0, newTex, sampler);
        }else{
            datablock.setTexture(0, newTex);
        }

        local compDef = CompositorDef(newWorkspace, newTex, datablock, compositorSceneType, newCamera, workspaceName);
        local id = registerNewCompositor_(compDef, compositorSceneType);

        //Add some uniqueness to the names.
        mTotalCompositors_++;

        print("Added compositor with id " + id)

        refreshRenderWindowWorkspace_();

        return id;
    }

    function resizeCompositor(compositor, size){
        local data = mActiveCompositors_[compositor];

        _compositor.removeWorkspace(data.mWorkspace);

        local tex = data.mTexture;
        tex.scheduleTransitionTo(_GPU_RESIDENCY_ON_STORAGE);
        tex.setResolution(size.x.tointeger(), size.y.tointeger());
        tex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);

        data.mWorkspace = _compositor.addWorkspace([tex], data.mCamera, data.mName, true);

        //data.mDatablock.setTexture(0, tex);

        //data.resize(size);
    }

    function destroyCompositorWorkspace(workspaceId){
        local data = mActiveCompositors_[workspaceId];
        mCompositorsForTypes[data.mType] = null;
        data.destroy();
        mActiveCompositors_[workspaceId] = null;
    }

    function getCameraForSceneType(sceneType){
        if(sceneType == CompositorSceneType.EXPLORATION){
            return mExplorationCamera;
        }
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
