//A tool to help select voxel colours.

function start(){

    local mModelViewWindow_ = _gui.createWindow();
    mModelViewWindow_.setZOrder(100);
    mModelViewWindow_.setPosition(0, 0);
    mModelViewWindow_.setSize(_window.getWidth(), _window.getHeight());
    mModelViewWindow_.setClipBorders(0, 0, 0, 0);

    local mModelViewPanel_ = mModelViewWindow_.createPanel();
    mModelViewPanel_.setPosition(0, 0);
    mModelViewPanel_.setSize(mModelViewWindow_.getSize());

    local mModelViewDatablock_ = _hlms.unlit.createDatablock("mapViewer/modelViewerRenderDatablock");
    mModelViewDatablock_.setTexture(0, "voxelPalette.png");

    mModelViewPanel_.setDatablock(mModelViewDatablock_);
}

function update(){
    local size = _window.getSize();
    if(_input.getMousePressed(_MB_LEFT)){
        local mouseX = _input.getMouseX();
        local mouseY = _input.getMouseY();

        local xIdx = (mouseX / (size.x / 16.0)).tointeger();
        local yIdx = (mouseY / (size.y / 16.0)).tointeger();

        local idx = xIdx + (yIdx * 16);

        local pressedButton = _window.showMessageBox({
            "title": "Voxel Index",
            "message": idx.tostring(),
            "buttons": [
                "OK",
            ]
        });
    }
}

function end(){

}