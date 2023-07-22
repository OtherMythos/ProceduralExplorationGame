::VisitedLocationMapViewer <- class extends ::MapViewer{

    mMapData_ = null;

    constructor(){
        setupBlendblock();
    }

    function fillBufferWithMap(textureBox){
        textureBox.seek(0);
        local width = mMapData_.width;
        local black = ColourValue(0, 0, 0, 1).getAsABGR();
        for(local y = 0; y < mMapData_.height; y++){
            for(local x = 0; x < width; x++){
                textureBox.writen(black, 'i');
            }
        }
    }

    function notifyNewPlaceFound(id, pos){
        //TODO Stub for now but in future dispatch this sort of thing with events.
    }
}