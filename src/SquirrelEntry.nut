function start(){
    ::mOrientation_ <- 0.0;

    _doFile("res://src/Constants.nut");

    _doFile("res://src/System/CompositorManager.nut");
    ::CompositorManager.setup();

    _gui.setScrollSpeed(5.0);

    //_camera.setProjectionType(_PT_ORTHOGRAPHIC);
    //_camera.setOrthoWindow(40, 40);
    _camera.setPosition(0, 0, 50);
    _camera.lookAt(0, 0, 0);
    //_camera.setPosition(1, 15, 5);

    {
        ::meshThing <- _mesh.create("goblin.mesh");

        local light = _scene.createLight();
        local lightNode = _scene.getRootSceneNode().createChildSceneNode();
        lightNode.attachObject(light);

        light.setType(_LIGHT_DIRECTIONAL);
        light.setDirection(-1, -1, -1);
        light.setPowerScale(PI);

        _scene.setAmbientLight(0xffffffff, 0xffffffff, Vec3(0, 1, 0));
    }

    local winSize = Vec2(_window.getWidth(), _window.getHeight());
    _gui.setCanvasSize(winSize, winSize);

    _doFile("res://src/Base.nut");
    ::Base.setup();
}

function update(){
    mOrientation_ += 0.01;
    local newOrientation = Quat(mOrientation_, Vec3(0, 1, 0));
    ::meshThing.setOrientation(newOrientation);

    ::Base.update();
}

function end(){

}