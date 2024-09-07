
function start(){
    _doFile("res://editorGUIFramework/src/EditorGUIFramework.nut");
    _doFile("res://sceneEditorFramework/SceneEditorFramework.nut");
    _gui.setDefaultFontSize26d6((_gui.getOriginalDefaultFontSize26d6()).tointeger());

    _doFile("res://SceneEditorFPSCamera.nut");
    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Logic/World/TerrainChunkManager.nut");

    _doFile("res://SceneEditorTerrainChunkManager.nut");
    _doFile("res://SceneEditor.nut");
    _doFile("res://SceneEditorGUITerrainToolProperties.nut");

    ::Base.setup();
}

function update(){
    ::Base.update();
}

function sceneSafeUpdate(){
    ::Base.sceneSafeUpdate();
}

function end(){
    ::Base.shutdown();
}
