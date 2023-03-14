enum DrawOptions{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    RIVER_DATA,
    LAND_GROUPS,

    MAX
};

::MapViewer <- class{

    mMapData_ = null;

    mDrawOptions_ = null;
    mDrawFlags_ = 0;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mFragmentParams_ = null

    constructor(){
        mDrawOptions_ = array(DrawOptions.MAX, false);
        mDrawOptions_[DrawOptions.WATER] = true;
        mDrawOptions_[DrawOptions.GROUND_TYPE] = true;

        setupCompositor();
    }

    function shutdown(){

    }

    function displayMapData(outData){
        mMapData_ = outData;

        local material = _graphics.getMaterialByName("mapViewer/mapMaterial");
        local fragmentParams = material.getFragmentProgramParameters(0, 0);

        fragmentParams.setNamedConstant("intBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("riverBuffer", outData.riverBuffer);
        fragmentParams.setNamedConstant("width", outData.width);
        fragmentParams.setNamedConstant("height", outData.height);
        fragmentParams.setNamedConstant("numWaterSeeds", outData.waterData.len());
        fragmentParams.setNamedConstant("numLandSeeds", outData.landData.len());
        fragmentParams.setNamedConstant("seaLevel", outData.seaLevel);

        mFragmentParams_ = fragmentParams;

        resubmitDrawFlags_();
    }

    function resubmitDrawFlags_(){
        local f = 0;
        for(local i = 0; i < DrawOptions.MAX; i++){
            if(mDrawOptions_[i]){
                f = f | (1 << i);
            }
        }

        mDrawFlags_ = f;
        print("new draw flags " + mDrawFlags_);
        mFragmentParams_.setNamedConstant("drawFlags", mDrawFlags_);
    }

    function setDrawOption(option, value){
        mDrawOptions_[option] = value;
        resubmitDrawFlags_();
    }

    function getDrawOption(option){
        return mDrawOptions_[option];
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