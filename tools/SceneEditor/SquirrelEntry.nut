
function start(){
    _doFile("res://../VoxToMesh/fpsCamera.nut");
    _doFile("res://../../src/Constants.nut");
    _doFile("res://sceneEditorFramework/SceneEditorBase.nut");
    _doFile("res://../../src/Logic/World/TerrainChunkManager.nut");
    _doFile("res://../../src/Logic/World/TerrainChunkFileHandler.nut");
    _doFile("res://../../src/Util/VoxToMesh.nut");

    _doFile("res://SceneEditor.nut");
    _doFile("res://SceneEditorGUITerrainToolProperties.nut");

    local winSize = Vec2(_window.getWidth(), _window.getHeight());
    _gui.setCanvasSize(winSize, winSize);

    ::Base.setup();
}

function update(){
    ::Base.update();
}

function sceneSafeUpdate(){
    ::Base.sceneSafeUpdate();
}

function end(){

}
