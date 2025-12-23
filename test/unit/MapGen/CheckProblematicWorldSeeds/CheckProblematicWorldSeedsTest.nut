//Test to check problematic world seeds for errors or crashes.

function start(){
    _gui.setScrollSpeed(5.0);

    ::resolutionMult <- _window.getActualSize() / _window.getSize();

    _doFile("res://../../../../src/System/EnumDef.nut");
    _doFile("res://../../../../src/Helpers.nut");
    _doFile("res://../../../../src/Constants.nut");
    _doFile("res://../../../../src/Content/PlaceEnums.nut");
    ::EnumDef.commitEnums();
    _doFile("res://../../../../src/Content/Places.nut");
    _doFile("res://../../../../src/Content/PlaceDefs.nut");
    _doFile("res://../../../../src/MapGen/Exploration/Generator/MapConstants.h.nut");
    _doFile("res://../../../../src/MapGen/Exploration/Generator/MapGenHelpers.nut");
    _doFile("res://../../../../src/MapGen/MapViewer.nut");
    _doFile("res://../../../../src/MapGen/Exploration/Viewer/ExplorationMapViewerConstants.h.nut");
    _doFile("res://../../../../src/MapGen/Exploration/Viewer/ExplorationMapViewer.nut");

    _doFile("script://CheckProblematicWorldSeedsBase.nut");

    ::CheckProblematicWorldSeedsBase.setup();
}

function update(){
    ::CheckProblematicWorldSeedsBase.update();
}

function end(){

}
