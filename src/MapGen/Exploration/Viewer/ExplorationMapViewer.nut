
::ExplorationMapViewer <- class extends ::MapViewer{

    mMapData_ = null;

    mColours_ = null;
    mOpacity_ = 0.4;

    mDrawOptions_ = null;
    mDrawOptionsHash_ = 0x0;
    mDrawLocationOptions_ = null;

    mCompositorDatablock_ = null
    mCompositorTexture_ = null

    mFragmentParams_ = null

    mPlaceMarkers_ = null;
    mFoundPlaces_ = null;
    mLabelWindow_ = null;

    constructor(currentFoundRegions=null){
        mDrawOptions_ = array(MapViewerDrawOptions.MAX, false);
        mDrawOptions_[MapViewerDrawOptions.WATER] = true;
        mDrawOptions_[MapViewerDrawOptions.GROUND_TYPE] = true;
        mDrawOptions_[MapViewerDrawOptions.VISIBLE_PLACES_MASK] = true;
        mDrawLocationOptions_ = array(PlaceType.MAX, true);
        mDrawLocationOptions_[PlaceType.CITY] = true;
        mDrawLocationOptions_[PlaceType.TOWN] = true;
        mDrawLocationOptions_[PlaceType.NONE] = false;
        mDrawOptionsHash_ = generateDrawOptionHash(mDrawOptions_);

        mPlaceMarkers_ = [];
        mFoundPlaces_ = [];

        setupBlendblock();
    }

    function shutdown(){
        base.shutdown();

        foreach(i in mFoundPlaces_){
            i.shutdown();
        }
    }

    function displayMapData(outData, nativeMapData=null, showPlaceMarkers=true, leanMap=false){
        base.displayMapData(outData, nativeMapData, showPlaceMarkers, leanMap);

        if(showPlaceMarkers){
            setupPlaceMarkers(outData);
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

    function generateDrawOptionHash(options){
        local hash = 0x0;
        foreach(c,i in options){
            if(!i) continue;
            hash = hash | (1 << c);
        }
        return hash;
    }
    function setDrawOption(option, value){
        mDrawOptions_[option] = value;
        mDrawOptionsHash_ = generateDrawOptionHash(mDrawOptions_);
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

    function fillBufferWithMap(textureBox){
        if(mLeanMap_){

            local timer = Timer();
            timer.start();

            _gameCore.fillBufferWithMapLean(textureBox, ::currentNativeMapData);

            timer.stop();
            local outTime = timer.getSeconds();
            printf("Time taken minimap %f seconds", outTime);
        }else{
            _gameCore.fillBufferWithMapComplex(textureBox, mNativeMapData_, mDrawOptionsHash_);
        }
    }

    function notifyRegionFound(regionId){
        uploadToTexture();
    }

    function notifyNewPlaceFound(id, pos){
        if(mMapData_ == null) return;
        local placeMarker = null;
        if(id == PlaceId.GATEWAY){
            placeMarker = PlaceMarkerIcon(mLabelWindow_, mMapData_, 5);
            placeMarker.setDatablock("placeMapGateway");
            placeMarker.setZOrder(100);
        }else{
            placeMarker = PlaceMarkerIcon(mLabelWindow_, mMapData_, 3);
        }
        placeMarker.setCentre(pos.x, pos.z);

        mFoundPlaces_.append(placeMarker);
    }

}