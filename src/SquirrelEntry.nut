function start(){
    _doFile("res://src/Constants.nut");

    ::buttonSize <- Vec2(350, 90);

    _camera.setProjectionType(_PT_ORTHOGRAPHIC);
    _camera.setOrthoWindow(40, 40);
    _camera.setPosition(0, 0, 5);
    _camera.lookAt(0, 0, 0);
    _camera.setPosition(1, 15, 5);

    local winSize = Vec2(_window.getWidth(), _window.getHeight());
    _gui.setCanvasSize(winSize, winSize);

    _doFile("res://src/Base.nut");
    ::Base.setup();
}

function update(){
    ::Base.update();
}

function end(){

}