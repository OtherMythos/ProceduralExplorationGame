function start(){
    _doFile("res://../src/MapGen/Viewer/MapViewer.nut");
    _doFile("res://../src/MapGen/Generator/MapGen.nut");

    _doFile("res://WorldGenToolBase.nut");

    ::WorldGenTool.setup();
}

function update(){
    ::WorldGenTool.update();
}

function end(){

}