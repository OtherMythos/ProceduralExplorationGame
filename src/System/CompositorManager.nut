//Some compositor scenes are generic.
//Giving them a designated type allows for things like easy access to cameras and queries.
enum CompositorSceneType{
    NONE,
    EXPLORATION,
    BG_EFFECT,
    FG_EFFECT,
    INVENTORY_PLAYER_INSPECTOR,

    MAX
};

::CompositorManager <- {
    mRenderWindowWorkspace_ = null

    mActiveCompositors_ = []
    mTotalCompositors_ = 0
    mCompositorsForTypes = array(CompositorSceneType.MAX, null)
    mTextures_ = []

    effectCam = null

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

        effectCam = _scene.createCamera("compositor/foregroundEffectCamera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(effectCam);

        cameraNode.setPosition(0, 0, EFFECT_WINDOW_CAMERA_Z);
        effectCam.lookAt(0, 0, 0);
        effectCam.setAspectRatio(_window.getWidth().tofloat() / _window.getHeight().tofloat());
        effectCam.setProjectionType(_PT_ORTHOGRAPHIC);
        effectCam.setOrthoWindow(20, 20);

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
        mRenderWindowWorkspace_ = _compositor.addWorkspace(textures, _camera.getCamera(), "renderWindowWorkspace", true);
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

        local compDef = CompositorDef(newWorkspace, newTex, datablock, compositorSceneType, newCamera);
        local id = registerNewCompositor_(compDef, compositorSceneType);

        //Add some uniqueness to the names.
        mTotalCompositors_++;

        print("Added compositor with id " + id)

        refreshRenderWindowWorkspace_();

        return id;
    }

    function destroyCompositorWorkspace(workspaceId){
        local data = mActiveCompositors_[workspaceId];
        mCompositorsForTypes[data.mType] = null;
        data.destroy();
        mActiveCompositors_[workspaceId] = null;
    }

    function getCameraForSceneType(sceneType){
        if(sceneType == CompositorSceneType.FG_EFFECT){
            return effectCam;
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
