function setupGui(){
    ::win <- _gui.createWindow();
    ::win.setPosition(0, 0);
    ::win.setSize(500, 500);

    local layout = _gui.createLayoutLine();
    local labels = ["Wireframe"];
    local functions = [
        function(widget, action){
            local datablock = _hlms.getDatablock("baseVoxelMaterial");
            datablock.setMacroblock(_hlms.getMacroblock({
                "polygonMode": widget.getValue() ? _PM_WIREFRAME : _PM_SOLID
            }));
        }
    ];
    foreach(c,i in labels){
        local button = ::win.createCheckbox();
        button.setText(i);
        button.attachListenerForEvent(functions[c], _GUI_ACTION_RELEASED);
        button.setValue(false);
        button.setUserId(c);
        layout.addCell(button);
    }

    ::timeTakenLabel <- ::win.createLabel();
    layout.addCell(::timeTakenLabel);

    layout.layout();

    ::win.setSize(::win.calculateChildrenSize());
}

function start(){
    _doFile("res://fpsCamera.nut");

    fpsCamera.start();

    setupGui();

    local otherNode = _scene.getRootSceneNode().createChildSceneNode();
    //otherNode.setPosition(-50, 0, 0);
    otherNode.attachObject(_gameCore.createVoxMeshItem("tree.voxMesh"));


    _camera.setPosition(0, 0, 40);
}

function update(){
    fpsCamera.update();

}

function end(){

}