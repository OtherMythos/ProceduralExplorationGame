//Just demonstrate an example of the voxel tool in use.

function start(){
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Character/CharacterModel.nut");
    _doFile("res://../../src/Character/CharacterGenerator.nut");
    _doFile("res://../../src/Character/CharacterModelTypes.nut");

    _doFile("res://../VoxToMesh/fpsCamera.nut");


    fpsCamera.start(Vec3());

    createGui();

    ::generator <- CharacterGenerator();

    local constructionData = {
        "test": null
    };

    local targetNode = _scene.getRootSceneNode().createChildSceneNode();
    ::inspectedModel <- ::generator.createCharacterModel(targetNode, constructionData);
    inspectedModel.startAnimation("HumanoidFeetWalk");

    _camera.setPosition(0, 0, 20);
    _camera.lookAt(0, 0, 0);
}

function update(){

    fpsCamera.update();
}

function end(){

}

function checkboxCallback(widget, action){
    local testVals = [
        "HumanoidFeetWalk",
        "HumanoidUpperWalk"
    ];
    if(widget.getValue()){
        print("hello");
        ::inspectedModel.startAnimation(testVals[widget.getUserId()]);
    }else{
        ::inspectedModel.stopAnimation(testVals[widget.getUserId()]);
    }
}

function createGui(){
    ::containerWin <- _gui.createWindow();
    containerWin.setSize(500, 500);
    local layout = _gui.createLayoutLine();

    local labels = [
        "FeetWalk",
        "UpperWalk"
    ];
    foreach(c,i in labels){
        local checkbox = ::containerWin.createCheckbox();
        checkbox.attachListenerForEvent(checkboxCallback, _GUI_ACTION_RELEASED);
        checkbox.setText(i);
        checkbox.setUserId(c);

        layout.addCell(checkbox);
        if(c == 0){
            checkbox.setValue(true);
        }
    }
    layout.layout();
}
