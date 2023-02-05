function start(){
    _doFile("res://src/Constants.nut");

    _doFile("res://src/System/CompositorManager.nut");
    ::CompositorManager.setup();

    _gui.setScrollSpeed(5.0);

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