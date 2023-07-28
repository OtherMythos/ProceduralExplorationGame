
function start(){
    _doFile("res://../VoxToMesh/fpsCamera.nut");
    _doFile("res://sceneEditorFramework/SceneEditorBase.nut");

    _doFile("res://SceneEditor.nut");

    ::Base.setup();
}

function update(){
    ::Base.update();
}

function end(){

}
