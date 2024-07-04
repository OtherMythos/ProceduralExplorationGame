function start(){
    _gui.setScrollSpeed(5.0);

    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Content/Places.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapConstants.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/Biomes.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapGen.nut");
    _doFile("res://../../src/MapGen/MapViewer.nut");
    _doFile("res://../../src/MapGen/Exploration/Viewer/ExplorationMapViewer.nut");

    ::GuiWidgets <- {};
    _doFile("res://../../src/GUI/Widgets/ProgressBar.nut");

    _doFile("res://WorldGenToolBase.nut");
    _doFile("res://fpsCamera.nut");

    ::WorldGenTool.setup();
}

function update(){
    ::WorldGenTool.update();
}

function end(){

}