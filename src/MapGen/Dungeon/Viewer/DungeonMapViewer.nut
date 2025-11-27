::DungeonMapViewer <- class extends ::MapViewer{

    mMapData_ = null;

    constructor(){
        setupBlendblock();
    }

    function fillBufferWithMap(textureBox){
        textureBox.seek(0);
        local v = mMapData_.vals;
        local width = mMapData_.width;
        local black = ColourValue(0, 0, 0, 0.2).getAsABGR();
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
}