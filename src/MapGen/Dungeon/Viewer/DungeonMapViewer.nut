::DungeonMapViewer <- class extends ::MapViewer{

    mMapData_ = null;

    mCompositorDatablock_ = null
    mCompositorTexture_ = null

    mPlayerLocationPanel_ = null;

    mFragmentParams_ = null

    constructor(){
        setupBlendblock();
    }

    function displayMapData(outData, showPlaceMarkers=true){
        mMapData_ = outData;

        setPlayerPosition(0.5, 0.5);

        local timer = Timer();
        timer.start();
            setupTextures(mMapData_);
            uploadToTexture();
        timer.stop();
        local outTime = timer.getSeconds();
        printf("Generating map texture took %f seconds", outTime);
    }

    function setDrawOption(option, value){
        mDrawOptions_[option] = value;
        uploadToTexture();
    }

    function fillBufferWithMap(textureBox){
        textureBox.seek(0);
        local v = mMapData_.vals;
        local width = mMapData_.width;
        local black = ColourValue(0, 0, 0, 1).getAsABGR();
        local white = ColourValue(1, 1, 1, 1).getAsABGR();
        for(local y = 0; y < mMapData_.height; y++){
            for(local x = 0; x < width; x++){
                textureBox.writen(v[x + y * width] != false ? white : black, 'i');
            }
        }
    }

    function notifyNewPlaceFound(id, pos){
        //TODO Stub for now but in future dispatch this sort of thing with events.
    }

    function setPlayerPosition(x, y){
        if(mMapData_ == null) return;
        if(mPlayerLocationPanel_ == null && mLabelWindow_){
            mPlayerLocationPanel_ = PlaceMarkerIcon(mLabelWindow_, mMapData_);
            mPlayerLocationPanel_.setDatablock("playerMapIndicator");
        }
        mPlayerLocationPanel_.setCentre(x.tofloat()/5, -y.tofloat()/5);
    }
}