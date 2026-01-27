//Some compositor scenes are generic.
//Giving them a designated type allows for things like easy access to cameras and queries.
enum CompositorSceneType{
    EXPLORATION,
    INVENTORY_PLAYER_INSPECTOR,
    OVERWORLD,
    RENDER_ICONS,

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

    mExtraTextures = null

    mGameplayActive_ = false
    mGameplayEffectsActive_ = false

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
        mExtraTextures = ::VersionPool();

        for(local i = 0; i < CompositorSceneType.MAX; i++){
            local newTex = _graphics.createTexture("compositor/renderTexture" + i);
            newTex.setResolution(100, 100);
            newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
            mTextures_.append(newTex);
        }

        mExplorationCamera = _scene.createCamera("explorationCamera");
        //Create extra scene nodes for the camera.
        //The highest level is what position and orientation is set to.
        //The second has animations and effects applied to it.
        //The third is what the camera is actually attached to for compatability with queries.
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode().createChildSceneNode().createChildSceneNode();
        cameraNode.attachObject(mExplorationCamera);

        mEffectCam = _scene.createCamera("compositor/foregroundEffectCamera");
        cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(mEffectCam);

        cameraNode.setPosition(0, 0, EFFECT_WINDOW_CAMERA_Z);
        mEffectCam.lookAt(0, 0, 0);
        mEffectCam.setAspectRatio(_window.getWidth().tofloat() / _window.getHeight().tofloat());
        mEffectCam.setProjectionType(_PT_ORTHOGRAPHIC);
        mEffectCam.setOrthoWindow(_window.getWidth().tofloat(), _window.getHeight().tofloat());

        ::FGEffectCamera <- mEffectCam;

        setGameplayActive(false);

        createRenderIconsWorkspace(_window.getSize() * ::resolutionMult);
    }

    function addExtraTexture(texture){
        return mExtraTextures.store(texture);
    }
    function removeExtraTexture(textureId){
        mExtraTextures.unstore(textureId);
        refreshRenderWindowWorkspace_();
    }

    function setGameplayActive(active){
        mGameplayActive_ = active;
        refreshRenderWindowWorkspace_();
    }

    function setGameplayEffectsActive(active){
        if(mGameplayEffectsActive_ == active) return;
        mGameplayEffectsActive_ = active;
        refreshRenderWindowWorkspace_();
    }

    function getRenderWorkspace_(){
        if(mGameplayActive_){
            if(mGameplayEffectsActive_){
                return "renderWindowWorkspaceGameplayWithEffects";
            }else{
                return "renderWindowWorkspaceGameplay";
            }
        }else{
            return "renderWindowWorkspace";
        }
    }

    function refreshRenderWindowWorkspace_(){
        if(mRenderWindowWorkspace_ != null){
            _compositor.removeWorkspace(mRenderWindowWorkspace_);
        }
        local textures = [_window.getRenderTexture()];
        foreach(i in mTextures_){
            textures.append(i);
        }

        foreach(i in mExtraTextures.mObject_){
            if(i == null) continue;
            textures.append(i);
        }

        local targetWorkspace = getRenderWorkspace_();
        mRenderWindowWorkspace_ = _compositor.addWorkspace(textures, _camera.getCamera(), targetWorkspace, true);
    }

    function createCompositorWorkspace(workspaceName, size, compositorSceneType, pointSampler=false, blend=true){
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

        local blendBlock = null;
        if(blend){
            blendBlock = _hlms.getBlendblock({
                "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
                "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
                "dst_alpha_blend_factor": _HLMS_SBF_ONE
            });
        }
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

    function createRenderIconsWorkspace(size){
        local workspaceId = createCompositorWorkspace("compositor/RenderIconsWorkspace", size, CompositorSceneType.RENDER_ICONS, false, true);
        local texture = mTextures_[CompositorSceneType.RENDER_ICONS];

        return workspaceId;
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
