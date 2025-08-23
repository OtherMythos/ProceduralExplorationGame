function start(){
    _gui.setScrollSpeed(5.0);

    ::resolutionMult <- _window.getActualSize() / _window.getSize();

    _doFile("res://../../src/System/EnumDef.nut");
    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Content/PlaceEnums.nut");
    _doFile("res://../../src/Content/VoxelEnums.nut");
    ::EnumDef.commitEnums();
    _doFile("res://../../src/Content/Places.nut");
    _doFile("res://../../src/Content/PlaceDefs.nut");
    _doFile("res://../../src/Content/VoxelDefs.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapConstants.h.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapGenHelpers.nut");
    _doFile("res://../../src/MapGen/MapViewer.nut");
    _doFile("res://../../src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut");
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