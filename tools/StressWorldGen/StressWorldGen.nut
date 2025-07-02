//A tool to repeatedly perform world gen tasks, to help find errors, memory leaks or crashes.

function start(){
    _gui.setScrollSpeed(5.0);

    ::resolutionMult <- _window.getActualSize() / _window.getSize();

    _doFile("res://../../src/System/EnumDef.nut");
    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Content/PlaceEnums.nut");
    ::EnumDef.commitEnums();
    _doFile("res://../../src/Content/Places.nut");
    _doFile("res://../../src/Content/PlaceDefs.h.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapConstants.h.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapGenHelpers.nut");
    _doFile("res://../../src/MapGen/Exploration/Generator/MapGen.nut");
    _doFile("res://../../src/MapGen/MapViewer.nut");
    _doFile("res://../../src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut");
    _doFile("res://../../src/MapGen/Exploration/Viewer/ExplorationMapViewer.nut");

    ::GuiWidgets <- {};
    _doFile("res://../../src/GUI/Widgets/ProgressBar.nut");

    _doFile("res://StressWorldGenBase.nut");

    ::StressWorldGenBase.setup();
}

function update(){
    ::StressWorldGenBase.update();
}

function end(){

}