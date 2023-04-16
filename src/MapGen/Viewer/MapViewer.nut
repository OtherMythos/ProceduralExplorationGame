enum DrawOptions{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    RIVER_DATA,
    LAND_GROUPS,
    EDGE_VALS,
    PLACE_LOCATIONS,
    VISIBLE_PLACES_MASK,

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

    mPlayerLocationPanel_ = null;

    mFragmentParams_ = null

    mPlaceMarkers_ = null;
    mLabelWindow_ = null;

    mVisiblePlacesBuffer_ = null;

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
        mDrawOptions_[DrawOptions.VISIBLE_PLACES_MASK] = false;
        mDrawLocationOptions_ = array(PlaceType.MAX, true);
        mDrawLocationOptions_[PlaceType.CITY] = true;
        mDrawLocationOptions_[PlaceType.TOWN] = true;
        mDrawLocationOptions_[PlaceType.NONE] = false;

        mPlaceMarkers_ = [];

        setupCompositor();
    }

    function shutdown(){

    }

    function displayMapData(outData, showPlaceMarkers=true){
        mMapData_ = outData;

        local material = _graphics.getMaterialByName("mapViewer/mapMaterial");
        local fragmentParams = material.getFragmentProgramParameters(0, 0);

        if(showPlaceMarkers){
            setupPlaceMarkers(outData);
        }

        mVisiblePlacesBuffer_ = setupVisiblePlacesBuffer(outData.width, outData.height);

        fragmentParams.setNamedConstant("intBuffer", outData.voxelBuffer);
        fragmentParams.setNamedConstant("riverBuffer", outData.riverBuffer);
        fragmentParams.setNamedConstant("placeBuffer", generatePlaceBuffer_(outData.placeData));
        fragmentParams.setNamedConstant("width", outData.width);
        fragmentParams.setNamedConstant("height", outData.height);
        fragmentParams.setNamedConstant("numWaterSeeds", outData.waterData.len());
        fragmentParams.setNamedConstant("numLandSeeds", outData.landData.len());
        fragmentParams.setNamedConstant("seaLevel", outData.seaLevel);
        //fragmentParams.setNamedConstant("visiblePlaceBuffer", mVisiblePlacesBuffer_);

        mFragmentParams_ = fragmentParams;

        resubmitDrawFlags_();
        resubmitDrawLocationFlags_();

        setPlayerPosition(0.5, 0.5);

        //setAreaVisible(100, 100, 10, 10);
    }

    function setupVisiblePlacesBuffer(width, height){
        //Using 2 bits to represent each voxel.
        local totalSize = ceil(((width * height) * 2).tofloat() / 8.0).tointeger();
        print("blob size " + totalSize);
        local buf = blob(totalSize);
        buf.seek(0);
        for(local i = 0; i < totalSize; i++){
            buf.writen(0, 'b')
        }
        return buf;
    }
    function setAreaVisible(x, y, radius, feather){
        /*
        mVisiblePlacesBuffer_.seek(0);
        for(local i = 0; i < 1000; i++){
            mVisiblePlacesBuffer_.writen(0xFF, 'b');
        }
        */
        local idx = (x + y * mMapData_.width) * 2;
        local byteIdx = (idx / 8).tointeger();
        local bitIdx = (idx % 8).tointeger();
        mVisiblePlacesBuffer_.seek(byteIdx);
        local val = mVisiblePlacesBuffer_.readn('b');
        local newVal = val | (0x3 << bitIdx * 2);
        mVisiblePlacesBuffer_.seek(byteIdx);
        mVisiblePlacesBuffer_.writen(newVal, 'b');

        //mFragmentParams_.setNamedConstant("visiblePlaceBuffer", mVisiblePlacesBuffer_);
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
        if(mLabelWindow_ == null) return;
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

    function setPlayerPosition(x, y){
        if(mPlayerLocationPanel_ == null && mLabelWindow_){
            mPlayerLocationPanel_ = mLabelWindow_.createPanel();
            mPlayerLocationPanel_.setSize(5, 5);
            mPlayerLocationPanel_.setPosition(0, 0);
            mPlayerLocationPanel_.setDatablock("playerMapIndicator");
        }

        local intendedPos = Vec2(x.tofloat() / mMapData_.width.tofloat(), y.tofloat() / mMapData_.height.tofloat());
        intendedPos *= mLabelWindow_.getSize();
        print("intended " + intendedPos.x);
        mPlayerLocationPanel_.setCentre(intendedPos.x, -intendedPos.y);

        //setAreaVisible(x, y, 10, 10);
    }

}