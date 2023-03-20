enum DrawOptions{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    RIVER_DATA,
    LAND_GROUPS,
    EDGE_VALS,
    PLACE_LOCATIONS,

    MAX
};

::MapViewer <- class{

    mMapData_ = null;

    mDrawOptions_ = null;
    mDrawFlags_ = 0;
    mDrawLocationOptions_ = null;
    mDrawLocationFlags_ = 0;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mFragmentParams_ = null

    mPlaceMarkers_ = null;
    mLabelWindow_ = null;

    PlaceMarker = class{

        mParentWin_ = null;
        mX_ = 0;
        mY_ = 0;
        mWidth_ = 0;
        mHeight_ = 0;
        mPlace_ = null;

        mLabel_ = null;
        mTypeSizes_ = [
            0, 30, 20, 15, 10
        ];
        mTypeColours_ = [
            null,
            ColourValue(1, 1, 1),
            ColourValue(0.8, 0.8, 0.8),
            ColourValue(0.7, 0.7, 0.7),
            ColourValue(0.65, 0.65, 0.65),
            ColourValue(0.55, 0.55, 0.55),
        ];

        constructor(window, x, y, width, height, place){
            mParentWin_ = window;
            mX_ = x;
            mY_ = y;
            mWidth_ = width;
            mHeight_ = height;
            mPlace_ = place;

            mLabel_ = mParentWin_.createLabel();
            local placeDef = ::Places[mPlace_];
            styleLabelForPlaceType(mLabel_, placeDef.getType());
            mLabel_.setText(placeDef.getName());
            local pos = Vec2(x.tofloat() / width.tofloat(), y.tofloat() / height.tofloat());
            mLabel_.setCentre(pos * window.getSize());
        }

        function styleLabelForPlaceType(label, type){
            label.setDefaultFontSize(mTypeSizes_[type]);
            label.setTextColour(mTypeColours_[type]);
            label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        }

        function shutdown(){
            _gui.destroy(mLabel_);
        }

        function updateForLocationFlags(flag){
            if(flag & 0x1){
                //Use none just to hide everything.
                mLabel_.setHidden(true);
                return;
            }
            local t = ::Places[mPlace_].getType();
            local visible = (flag >> t) & 0x1;
            mLabel_.setHidden(!visible);
        }
    };

    constructor(){
        mDrawOptions_ = array(DrawOptions.MAX, false);
        mDrawOptions_[DrawOptions.WATER] = true;
        mDrawOptions_[DrawOptions.GROUND_TYPE] = true;
        mDrawLocationOptions_ = array(PlaceType.MAX, true);
        mDrawLocationOptions_[PlaceType.CITY] = true;
        mDrawLocationOptions_[PlaceType.TOWN] = true;
        mDrawLocationOptions_[PlaceType.NONE] = false;

        mPlaceMarkers_ = [];

        setupCompositor();
    }

    function shutdown(){

    }

    function displayMapData(outData){
        mMapData_ = outData;

        local material = _graphics.getMaterialByName("mapViewer/mapMaterial");
        local fragmentParams = material.getFragmentProgramParameters(0, 0);

        setupPlaceMarkers(outData);

        fragmentParams.setNamedConstant("intBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("riverBuffer", outData.riverBuffer);
        fragmentParams.setNamedConstant("placeBuffer", generatePlaceBuffer_(outData.placeData));
        fragmentParams.setNamedConstant("width", outData.width);
        fragmentParams.setNamedConstant("height", outData.height);
        fragmentParams.setNamedConstant("numWaterSeeds", outData.waterData.len());
        fragmentParams.setNamedConstant("numLandSeeds", outData.landData.len());
        fragmentParams.setNamedConstant("seaLevel", outData.seaLevel);

        mFragmentParams_ = fragmentParams;

        resubmitDrawFlags_();
        resubmitDrawLocationFlags_();
    }

    function generatePlaceBuffer_(placeData){
        local b = blob(placeData.len() * 4);
        foreach(i in placeData){
            b.writen(i.originWrapped, 'i');
        }
        b.writen(0xFFFFFFFF, 'i');

        return b;
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

    function resubmitDrawLocationFlags_(){
        local f = 0;
        for(local i = 0; i < PlaceType.MAX; i++){
            print(mDrawLocationOptions_[i]);
            if(mDrawLocationOptions_[i]){
                f = f | (1 << i);
            }
        }

        mDrawLocationFlags_ = f;
        print("new draw location flags " + mDrawLocationFlags_);

        foreach(i in mPlaceMarkers_){
            i.updateForLocationFlags(mDrawLocationFlags_);
        }
    }

    function setupPlaceMarkers(outData){
        for(local i = 0; i < mPlaceMarkers_.len(); i++){
            mPlaceMarkers_[i].shutdown();
        }

        mPlaceMarkers_.clear();
        foreach(c,i in outData.placeData){
            local placeMarker = PlaceMarker(mLabelWindow_, i.originX, i.originY, outData.width, outData.height, i.placeId);
            mPlaceMarkers_.append(placeMarker);
        }
    }

    function setDrawOption(option, value){
        mDrawOptions_[option] = value;
        resubmitDrawFlags_();
    }

    function setLocationDrawOption(option, value){
        mDrawLocationOptions_[option] = value;
        resubmitDrawLocationFlags_();
    }

    function getDrawOption(option){
        return mDrawOptions_[option];
    }

    function getLocationDrawOption(option){
        return mDrawLocationOptions_[option];
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

    function setLabelWindow(renderWindow){
        mLabelWindow_ = renderWindow;
    }

}