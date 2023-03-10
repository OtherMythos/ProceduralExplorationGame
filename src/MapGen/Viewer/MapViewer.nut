::MapViewer <- class{

    mMapData_ = null;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    constructor(){
        setupCompositor();
    }

    function displayMapData(outData){
        mMapData_ = outData;

        local material = _graphics.getMaterialByName("worldGenToolViewer");
        local fragmentParams = material.getFragmentProgramParameters(0, 0);

        fragmentParams.setNamedConstant("testBuffer", outData.voxelBuffer);
    }

    function setupCompositor(){
        local newTex = _graphics.createTexture("compositor/renderTexture");
        newTex.setResolution(1920, 1080);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mCompositorTexture_ = newTex;

        local newCamera = _scene.createCamera("compositor/camera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);
        mCompositorCamera_ = newCamera;

        local datablock = _hlms.unlit.createDatablock("renderTextureDatablock");
        datablock.setTexture(0, newTex);
        mCompositorDatablock_ = datablock;

        //TODO might want to make this not auto update. 
        if(mCompositorWorkspace_ != null){
            _compositor.removeWorkspace(mCompositorWorkspace_);
            mCompositorWorkspace_ = null;
        }
        //Re-generate the compositor so I can pass the new textures to it.
        mCompositorWorkspace_ = _compositor.addWorkspace([mCompositorTexture_], mCompositorCamera_, "renderTextureWorkspace", true);
    }

    function getDatablock(){
        return mCompositorDatablock_;
    }

}