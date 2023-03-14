enum drawMasks{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    RIVER_DATA
};

::MapViewer <- class{

    mMapData_ = null;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mFragmentParams_ = null

    mDrawWater_ = true;
    mDrawGroundType_ = true;
    mDrawWaterGroups_ = 0;
    mDrawRiverData_ = 0;
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

        fragmentParams.setNamedConstant("intBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("riverBuffer", outData.riverBuffer);
        fragmentParams.setNamedConstant("width", outData.width);
        fragmentParams.setNamedConstant("height", outData.height);
        fragmentParams.setNamedConstant("numWaterSeeds", outData.waterSeeds.len());
        fragmentParams.setNamedConstant("seaLevel", outData.seaLevel);

        mFragmentParams_ = fragmentParams;

        resubmitDrawFlags_();
    }

    function resubmitDrawFlags_(){
        local f = 0;
        if(mDrawWater_) f = f | (1 << drawMasks.WATER);
        if(mDrawGroundType_) f = f | (1 << drawMasks.GROUND_TYPE);
        if(mDrawWaterGroups_) f = f | (1 << drawMasks.WATER_GROUPS);
        if(mDrawRiverData_) f = f | (1 << drawMasks.RIVER_DATA);

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

    function setDrawWaterGroups(waterGroups){
        mDrawWaterGroups_ = waterGroups;
        resubmitDrawFlags_();
    }

    function setDrawRiverData(riverData){
        mDrawRiverData_ = riverData;
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