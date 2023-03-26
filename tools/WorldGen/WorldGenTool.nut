function start(){
    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Content/Places.nut");
    _doFile("res://../../src/MapGen/Viewer/MapViewer.nut");
    _doFile("res://../../src/MapGen/Generator/MapGen.nut");

    _doFile("res://WorldGenToolBase.nut");
    _doFile("res://fpsCamera.nut");

    ::WorldGenTool.setup();
}

function update(){
    ::WorldGenTool.update();
}

function end(){

}