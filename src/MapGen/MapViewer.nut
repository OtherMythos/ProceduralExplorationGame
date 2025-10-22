
::MapViewerCount <- 0;

::MapViewer <- class{

    mMapData_ = null;
    mNativeMapData_ = null;
    mLeanMap_ = false;

    mCompositorDatablock_ = null
    mCompositorTexture_ = null

    mPlayerLocationPanel_ = null;

    mLabelWindow_ = null;

    PlaceMarkerIcon = class{
        mPanel_ = null;
        mParent_ = null;
        mMapData_ = null;
        mMapScale_ = null;
        constructor(parentWin, mapData, size=5, scale=1){
            mParent_ = parentWin;
            mMapData_ = mapData;
            mMapScale_ = scale;

            mPanel_ = parentWin.createPanel();
            mPanel_.setSize(size, size);
            mPanel_.setPosition(0, 0);
            mPanel_.setDatablock("gui/basicTransparentFull");
            setColour(ColourValue(1, 0, 0, 1.0));
        }
        function setCentre(x, y){
            printf("x: %f y: %f", x, y);
            local intendedPos = Vec2(x.tofloat() / mMapData_.width.tofloat(), y.tofloat() / mMapData_.height.tofloat());
            intendedPos *= mParent_.getSize();
            mPanel_.setCentre(intendedPos.x / mMapScale_, intendedPos.y / mMapScale_);
            //mPanel_.setCentre(intendedPos.x, -intendedPos.y);
        }
        function setColour(colour){
            mPanel_.setColour(ColourValue(1, 0, 0, colour.a));
        }
        function setVisible(visible){
            mPanel_.setVisible(visible);
        }
        function setZOrder(zOrder){
            mPanel_.setZOrder(zOrder);
        }
        function shutdown(){
            _gui.destroy(mPanel_);
        }
    };

    PlaceMarker = class{

        mParentWin_ = null;
        mX_ = 0;
        mY_ = 0;
        mWidth_ = 0;
        mHeight_ = 0;
        mPlace_ = null;

        mLabel_ = null;
        mTypeSizes_ = [
            0, 20, 30, 20, 15, 10
        ];
        mTypeColours_ = [
            null,
            ColourValue(0.2, 0.2, 1),
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
            label.setDefaultFontSize(mTypeSizes_[type] * ::resolutionMult.x);
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
        setupBlendblock();
    }

    function shutdown(){
        _hlms.destroyDatablock(mCompositorDatablock_);
        _graphics.destroyTexture(mCompositorTexture_);
    }

    function displayMapData(outData, nativeData=null, showPlaceMarkers=true, leanMap=false){
        if(outData == null) return;
        mMapData_ = outData;
        mNativeMapData_ = nativeData;
        mLeanMap_ = leanMap;

        setPlayerPosition(0.5, 0.5);

        local timer = Timer();
        timer.start();
            setupTextures(mMapData_);
            uploadToTexture();
        timer.stop();
        local outTime = timer.getSeconds();
        printf("Generating map texture took %f seconds", outTime);
    }

    function setupBlendblock(){
        ::MapViewerCount++;
        local blend = _hlms.getBlendblock({
            "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
            "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
            "dst_alpha_blend_factor": _HLMS_SBF_ONE
        });
        local datablock = _hlms.unlit.createDatablock("mapViewer/renderDatablock" + ::MapViewerCount, blend);
        mCompositorDatablock_ = datablock;
    }
    function setupTextures(mapData){
        //TODO check for the old texture and destroy that as well.
        //mCompositorDatablock_.setTexture(0, null);
        if(mCompositorTexture_){
            _graphics.destroyTexture(mCompositorTexture_);
            mCompositorTexture_ = null;
        }

        local newTex = _graphics.createTexture("mapViewer/renderTexture" + ::MapViewerCount);
        local width = mapData.width;
        local height = mapData.height;
        if(width == 0 || height == 0){
            width = 500;
            height = 500;
        }
        newTex.setResolution(width, height);
        newTex.setPixelFormat(_PFG_RGBA8_UNORM);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mCompositorTexture_ = newTex;

        assert(mCompositorDatablock_ != null);
        local sampler = _hlms.getSamplerblock({
            "mag": "point"
        });
        mCompositorDatablock_.setTexture(0, mCompositorTexture_, sampler);
    }

    function uploadToTexture(){
        if(mMapData_.width == 0 || mMapData_.height == 0) return;
        //TODO change this.
        local stagingTexture = _graphics.getStagingTexture(mMapData_.width, mMapData_.height, 1, 1, _PFG_RGBA8_UNORM);
        stagingTexture.startMapRegion();
        local textureBox = stagingTexture.mapRegion(mMapData_.width, mMapData_.height, 1, 1, _PFG_RGBA8_UNORM);

        fillBufferWithMap(textureBox);

        stagingTexture.stopMapRegion();
        stagingTexture.upload(textureBox, mCompositorTexture_, 0);
        mCompositorTexture_.barrierSolveTexture();
    }

    function getDatablock(){
        return mCompositorDatablock_;
    }

    function setLabelWindow(renderWindow){
        mLabelWindow_ = renderWindow;
    }

    function shutdown(){
        if(mCompositorDatablock_ != null) _hlms.destroyDatablock(mCompositorDatablock_);
        if(mCompositorTexture_ != null) _graphics.destroyTexture(mCompositorTexture_);

        if(mPlayerLocationPanel_ != null){
            mPlayerLocationPanel_.shutdown();
        }
    }

    function setColour(colour){
        if(mPlayerLocationPanel_ != null){
            mPlayerLocationPanel_.setColour(colour);
        }
    }

    function setVisible(visible){
        if(mPlayerLocationPanel_ != null){
            mPlayerLocationPanel_.setVisible(visible);
        }
    }

    function setPlayerPosition(x, y, worldScale=1){
        if(mMapData_ == null) return;
        if(mLabelWindow_ == null) return;

        if(mPlayerLocationPanel_ == null){
            mPlayerLocationPanel_ = PlaceMarkerIcon(mLabelWindow_, mMapData_, 5, worldScale);
        }
        mPlayerLocationPanel_.setCentre(x, y);
    }

    function getMinimapVisible(){
        return true;
    }

}