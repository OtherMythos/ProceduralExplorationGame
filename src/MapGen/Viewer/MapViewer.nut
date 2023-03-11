enum drawMasks{
    WATER,
    GROUND_TYPE
};

::MapViewer <- class{

    mMapData_ = null;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mFragmentParams_ = null

    mDrawWater_ = false;
    mDrawGroundType_ = false;
    mDrawFlags_ = 0;

    constructor(){
        setupCompositor();
    }

    function shutdown(){

    }

    function displayMapData(outData){
        mMapData_ = outData;

        local material = _graphics.getMaterialByName("mapViewer/mapMaterial");
        local fragmentParams = material.getFragmentProgramParameters(0, 0);

        //fragmentParams.setNamedConstant("floatBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("intBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("width", outData.width);
        fragmentParams.setNamedConstant("height", outData.height);
        mFragmentParams_ = fragmentParams;
    }

    function resubmitDrawFlags_(){
        local f = 0;
        if(mDrawWater_) f = f | (1 << drawMasks.WATER);
        if(mDrawGroundType_) f = f | (1 << drawMasks.GROUND_TYPE);

        mDrawFlags_ = f;
        print("new draw flags " + mDrawFlags_);
        mFragmentParams_.setNamedConstant("drawFlags", mDrawFlags_);
    }

    function setDrawWater(water){
        mDrawWater_ = water;
        resubmitDrawFlags_();
    }

    function setDrawGroundVoxels(ground){
        mDrawGroundType_ = ground;
        resubmitDrawFlags_();
    }

    function setupCompositor(){
        local newTex = _graphics.createTexture("mapViewer/renderTexture");
        newTex.setResolution(1920, 1080);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mCompositorTexture_ = newTex;

        local newCamera = _scene.createCamera("mapViewer/camera");
        local cameraNode = _scene.getRootSceneNode().createChildSceneNode();
        cameraNode.attachObject(newCamera);
        mCompositorCamera_ = newCamera;

        local datablock = _hlms.unlit.createDatablock("mapViewer/renderDatablock");
        datablock.setTexture(0, newTex);
        mCompositorDatablock_ = datablock;

        //TODO might want to make this not auto update.
        mCompositorWorkspace_ = _compositor.addWorkspace([mCompositorTexture_], mCompositorCamera_, "mapViewer/renderTextureWorkspace", true);
    }

    function getDatablock(){
        return mCompositorDatablock_;
    }

}