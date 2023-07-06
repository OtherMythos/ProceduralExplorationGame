enum DrawOptions{
    WATER,
    GROUND_TYPE,
    WATER_GROUPS,
    MOISTURE_MAP,
    RIVER_DATA,
    LAND_GROUPS,
    EDGE_VALS,
    PLACE_LOCATIONS,
    VISIBLE_PLACES_MASK,

    MAX
};

enum MapViewerColours{
    VOXEL_GROUP_GROUND,
    VOXEL_GROUP_GRASS,
    VOXEL_GROUP_ICE,
    VOXEL_GROUP_TREES,

    OCEAN,
    FRESH_WATER,
    WATER_GROUPS,

    COLOUR_BLACK,
    COLOUR_MAGENTA,

    MAX
};

::MapViewer <- class{

    mMapData_ = null;

    mColours_ = null;
    mOpacity_ = 0.4;

    mDrawOptions_ = null;
    mDrawLocationOptions_ = null;

    mCompositorDatablock_ = null
    mCompositorWorkspace_ = null
    mCompositorCamera_ = null
    mCompositorTexture_ = null

    mPlayerLocationPanel_ = null;

    mFragmentParams_ = null

    mPlaceMarkers_ = null;
    mLabelWindow_ = null;

    mVisiblePlacesBuffer_ = null;

    PlaceMarkerIcon = class{
        mPanel_ = null;
        mParent_ = null;
        mMapData_ = null;
        constructor(parentWin, mapData, size=5){
            mParent_ = parentWin;
            mMapData_ = mapData;

            mPanel_ = parentWin.createPanel();
            mPanel_.setSize(size, size);
            mPanel_.setPosition(0, 0);
            setDatablock("placeMapIndicator");
        }
        function setCentre(x, y){
            local intendedPos = Vec2(x.tofloat() / mMapData_.width.tofloat(), y.tofloat() / mMapData_.height.tofloat());
            intendedPos *= mParent_.getSize();
            mPanel_.setCentre(intendedPos.x, -intendedPos.y);
        }
        function setDatablock(datablock){
            mPanel_.setDatablock(datablock);
        }
        function setZOrder(zOrder){
            mPanel_.setZOrder(zOrder);
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

        setupBlendblock();
        setupColours();

        //setupCompositor();
    }

    function shutdown(){
        //_compositor.removeWorkspace(mCompositorWorkspace_);
        _hlms.destroyDatablock(mCompositorDatablock_);
        //mCompositorCamera_.getParentNode().destroyNodeAndChildren();
        _graphics.destroyTexture(mCompositorTexture_);
    }

    function displayMapData(outData, showPlaceMarkers=true){
        mMapData_ = outData;

        if(showPlaceMarkers){
            setupPlaceMarkers(outData);
        }

        mVisiblePlacesBuffer_ = setupVisiblePlacesBuffer(outData.width, outData.height);

        setPlayerPosition(0.5, 0.5);

        local timer = Timer();
        timer.start();
            setupTextures(mMapData_);
            uploadToTexture();
        timer.stop();
        local outTime = timer.getSeconds();
        printf("Generating map texture took %f seconds", outTime);
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
        uploadToTexture();
    }

    function setLocationDrawOption(option, value){
        mDrawLocationOptions_[option] = value;

        local f = 0;
        for(local i = 0; i < PlaceType.MAX; i++){
            if(mDrawLocationOptions_[i]){
                f = f | (1 << i);
            }
        }


        foreach(i in mPlaceMarkers_){
            i.updateForLocationFlags(f);
        }
    }

    function getDrawOption(option){
        return mDrawOptions_[option];
    }

    function getLocationDrawOption(option){
        return mDrawLocationOptions_[option];
    }

    function setupColours(){
        local colVals = array(MapViewerColours.MAX);
        local baseVal = ColourValue(0, 0, 0, 1);
        colVals[MapViewerColours.VOXEL_GROUP_GROUND] = ColourValue(0.84, 0.87, 0.29, 1);
        colVals[MapViewerColours.VOXEL_GROUP_GRASS] = ColourValue(0.33, 0.92, 0.27, 1);
        colVals[MapViewerColours.VOXEL_GROUP_ICE] = ColourValue(0.84, 0.88, 0.84, 1);
        colVals[MapViewerColours.VOXEL_GROUP_TREES] = ColourValue(0.33, 0.66, 0.005, 1);
        colVals[MapViewerColours.OCEAN] = ColourValue(0, 0, 1.0, mOpacity_);
        colVals[MapViewerColours.FRESH_WATER] = ColourValue(0.15, 0.15, 1.0, mOpacity_);
        colVals[MapViewerColours.WATER_GROUPS] = baseVal;
        colVals[MapViewerColours.COLOUR_BLACK] = baseVal;
        colVals[MapViewerColours.COLOUR_MAGENTA] = ColourValue(1, 0, 1, 1);

        for(local i = 0; i < colVals.len(); i++){
            colVals[i] = colVals[i].getAsABGR();
        }
        mColours_ = colVals;
    }

    function setupBlendblock(){
        local blend = _hlms.getBlendblock({
            "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
            "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
            "dst_alpha_blend_factor": _HLMS_SBF_ONE
        });
        local datablock = _hlms.unlit.createDatablock("mapViewer/renderDatablock", blend);
        mCompositorDatablock_ = datablock;
    }
    function setupTextures(mapData){
        //TODO check for the old texture and destroy that as well.
        //mCompositorDatablock_.setTexture(0, null);
        if(mCompositorTexture_){
            _graphics.destroyTexture(mCompositorTexture_);
            mCompositorTexture_ = null;
        }

        local newTex = _graphics.createTexture("mapViewer/renderTexture");
        newTex.setResolution(mapData.width, mapData.height);
        newTex.setPixelFormat(_PFG_RGBA8_UNORM);
        newTex.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);
        mCompositorTexture_ = newTex;

        assert(mCompositorDatablock_ != null);
        mCompositorDatablock_.setTexture(0, mCompositorTexture_);
    }

    function uploadToTexture(){
        //TODO change this.
        local stagingTexture = _graphics.getStagingTexture(mMapData_.width, mMapData_.height, 1, 1, _PFG_RGBA8_UNORM);
        stagingTexture.startMapRegion();
        local textureBox = stagingTexture.mapRegion(mMapData_.width, mMapData_.height, 1, 1, _PFG_RGBA8_UNORM);

        fillBufferWithMap(textureBox);

        stagingTexture.stopMapRegion();
        stagingTexture.upload(textureBox, mCompositorTexture_, 0);
    }

    function fillBufferWithMap(textureBox){
        mMapData_.voxelBuffer.seek(0);
        for(local y = 0; y < mMapData_.height; y++){
            local yVal = (y.tofloat() / mMapData_.height) * 0x80;
            for(local x = 0; x < mMapData_.width; x++){
                local colour = _getColourForVox(x, y);
                textureBox.writen(colour, 'i');
            }
        }
    }

    function _getColourForVox(xVox, yVox){
        local voxVal = mMapData_.voxelBuffer.readn('i');
        local altitude = voxVal & 0xFF;
        local voxelMeta = (voxVal >> 8) & MAP_VOXEL_MASK;
        local waterGroup = (voxVal >> 16) & 0xFF;

        local drawVal = 0x0;

        if(mDrawOptions_[DrawOptions.GROUND_TYPE]){
            if((voxVal >> 8) & MapVoxelTypes.RIVER){
                drawVal = mColours_[MapViewerColours.FRESH_WATER];
            }else{
                drawVal = mColours_[voxelMeta];
            }
        }else{
            //NOTE: Slight optimisation.
            //Most cases will have ground type enabled, so no point doing this check unless needed.
            local val = altitude.tofloat() / 0xFF;
            drawVal = ColourValue(val, val, val, 1).getAsABGR();
        }
        if(mDrawOptions_[DrawOptions.WATER]){
            if(altitude < mMapData_.seaLevel){
                if(waterGroup == 0){
                    drawVal = mColours_[MapViewerColours.OCEAN];
                }else{
                    drawVal = mColours_[MapViewerColours.FRESH_WATER];
                }
            }
        }
        if(mDrawOptions_[DrawOptions.WATER_GROUPS]){
            local valGroup = waterGroup.tofloat() / mMapData_.waterData.len();
            drawVal = ColourValue(valGroup, valGroup, valGroup, mOpacity_).getAsABGR();
        }
        if(mDrawOptions_[DrawOptions.MOISTURE_MAP]){
            mMapData_.moistureBuffer.seek((xVox + yVox * mMapData_.width) * 4);
            local moistureVal = mMapData_.moistureBuffer.readn('i');

            local val = moistureVal.tofloat() / 0xFF;
            drawVal = ColourValue(val, val, val, 1).getAsABGR();
        }
        if(mDrawOptions_[DrawOptions.RIVER_DATA]){
            //local i = 0;
            mMapData_.riverBuffer.seek(0);
            local first = true;
            while(true){
                //local riverVal = mMapData_.riverBuffer[i];
                local riverVal = mMapData_.riverBuffer.readn('i');
                if(first && riverVal < 0){
                    break;
                }
                local x = (riverVal >> 16) & 0xFFFF;
                local y = riverVal & 0xFFFF;
                if(xVox == x && yVox == y){
                    drawVal = first ? mColours_[MapViewerColours.COLOUR_MAGENTA] : mColours_[MapViewerColours.COLOUR_BLACK];
                }
                first = false;
                //i++;
                if(riverVal < 0){
                    first = true;
                }
            }
        }
        if(mDrawOptions_[DrawOptions.LAND_GROUPS]){
            local landGroup = (voxVal >> 24) & 0xFF;
            local valGroup = landGroup.tofloat() / mMapData_.landData.len();
            drawVal = ColourValue(valGroup, valGroup, valGroup, mOpacity_).getAsABGR();
        }
        if(mDrawOptions_[DrawOptions.EDGE_VALS]){
            local edgeVox = (voxVal >> 8) & 0x80;
            if(edgeVox){
                drawVal = mColours_[MapViewerColours.COLOUR_BLACK];
            }
        }
        if(mDrawOptions_[DrawOptions.PLACE_LOCATIONS]){
            foreach(i in mMapData_.placeData){
                if(xVox == i.originX && yVox == i.originY){
                    drawVal = mColours_[MapViewerColours.COLOUR_BLACK];
                    break;
                }
            }
        }
        if(mDrawOptions_[DrawOptions.VISIBLE_PLACES_MASK]){
            local idx = (xVox + yVox * p.width) * 2;
            local byteIdx = int(idx / 32);
            local bitIdx = idx % 32;
            local val = (p.visiblePlaceBuffer[byteIdx] >> (bitIdx)) & 0x3;

            local col = float4(0, 0, 0, mOpacity_);
            if(val & 0x2) col = drawVal;
            else if(val & 0x1) col = float4(0.4, 0.4, 0.4, mOpacity_);

            drawVal = col;
        }

        return drawVal;
    }

    function getDatablock(){
        return mCompositorDatablock_;
    }

    function setLabelWindow(renderWindow){
        mLabelWindow_ = renderWindow;
    }

    function setPlayerPosition(x, y){
        if(mPlayerLocationPanel_ == null && mLabelWindow_){
            mPlayerLocationPanel_ = PlaceMarkerIcon(mLabelWindow_, mMapData_);
            mPlayerLocationPanel_.setDatablock("playerMapIndicator");
        }
        mPlayerLocationPanel_.setCentre(x, y);
    }

    function notifyNewPlaceFound(id, pos){
        local placeMarker = null;
        if(id == PlaceId.GATEWAY){
            placeMarker = PlaceMarkerIcon(mLabelWindow_, mMapData_, 5);
            placeMarker.setDatablock("placeMapGateway");
            placeMarker.setZOrder(100);
        }else{
            placeMarker = PlaceMarkerIcon(mLabelWindow_, mMapData_, 3);
        }
        placeMarker.setCentre(pos.x, pos.z);
    }

}