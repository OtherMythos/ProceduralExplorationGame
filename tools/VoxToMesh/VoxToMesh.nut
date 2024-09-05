enum DemoTypes{
    DATA_TO_VOX,
    RANDOM_TO_VOX,

    MAX
};

::USE_NATIVE <- false;

::setDemoType <- function(id){
    if(::currentDemo != null){
        ::currentDemo.end();
    }
    ::currentDemo = ::demos[id]();
    ::currentDemo.start();
}

function widgetCallback(widget, action){
    local idx = widget.getUserId();
    setDemoType(idx);
}
function nativeToggleListener(widget, action){
    USE_NATIVE = widget.getValue();
};
function setupGui(){
    ::win <- _gui.createWindow();
    ::win.setPosition(0, 0);
    ::win.setSize(500, 500);

    local layout = _gui.createLayoutLine();
    local labels = ["data to vox", "random to vox"];
    foreach(i,c in labels){
        local button = ::win.createButton();
        button.setText(c);
        button.attachListenerForEvent(widgetCallback, _GUI_ACTION_PRESSED);
        button.setUserId(i);
        layout.addCell(button);
    }

    if(getroottable().rawin("_gameCore")){
        local nativeToggle = ::win.createCheckbox();
        nativeToggle.setText("Use native");
        nativeToggle.attachListenerForEvent(nativeToggleListener, _GUI_ACTION_RELEASED);
        nativeToggle.setValue(::USE_NATIVE);
        layout.addCell(nativeToggle);
    }

    ::timeTakenLabel <- ::win.createLabel();
    ::registerTimeTaken(0.0);
    layout.addCell(::timeTakenLabel);

    layout.layout();
}

::registerTimeTaken <- function(time){
    local string = format("Time taken: %f", time);
    print(string);
    ::timeTakenLabel.setText(string);
}

::demos <- array(DemoTypes.MAX);
::currentDemo <- null;

::VoxDemo <- class{
    mNode_ = null;
    mMesh_ = null;
    function start() { }
    function update() { }
    function end() {
        if(mNode_ != null){
            mNode_.destroyNodeAndChildren();
            printf("Destroying mesh with name %s", mMesh_.getName());
            _graphics.removeManualMesh(mMesh_.getName());
        }
    }

    function basicMesh(voxData, width, height, depth){
        local voxMesh = VoxToMesh();

        //If we have access to native voxelisation try that.
        local meshObj = null;
        local t = Timer();
        t.start();
        if(getroottable().rawin("_gameCore") && USE_NATIVE){
            meshObj = _gameCore.voxeliseMeshForVoxelData("testVox", voxData, width, height, depth);
        }else{
            meshObj = voxMesh.createMeshForVoxelData("testVox", voxData, width, height, depth);
        }
        t.stop();
        mMesh_ = meshObj;

        ::registerTimeTaken(t.getSeconds());

        local item = _gameCore.createVoxMeshItem(meshObj);
        local newNode = _scene.getRootSceneNode().createChildSceneNode();
        newNode.attachObject(item);

        mNode_ = newNode;
    }
}

demos[DemoTypes.DATA_TO_VOX] = class extends ::VoxDemo{
    function start(){
        local width = 10;
        local height = 10;
        local depth = 10;
        local voxData = array(width * height * depth, null);

        voxData[4 + (1*width) + (0*width*height)] = 1;
        voxData[3 + (0*width) + (0*width*height)] = 1;
        voxData[2 + (0*width) + (0*width*height)] = 1;
        voxData[1 + (0*width) + (0*width*height)] = 1;
        voxData[0 + (1*width) + (0*width*height)] = 1;

        voxData[0 + (5*width) + (0*width*height)] = 254;
        voxData[4 + (5*width) + (0*width*height)] = 254;

        basicMesh(voxData, width, height, depth);
    }
}

demos[DemoTypes.RANDOM_TO_VOX] = class extends ::VoxDemo{
    mNode_ = null;
    mMesh_ = null;
    function start(){
        local width = 20;
        local height = 20;
        local depth = 20;
        local voxData = array(width * height * depth, null);

        for(local z = 0; z < depth; z++)
        for(local y = 0; y < height; y++)
        for(local x = 0; x < height; x++){
            if(_random.randInt(10) != 0) continue;
            voxData[x + (y * width) + (z * width * height)] = 1;
        }

        basicMesh(voxData, width, height, depth);
    }
}

function start(){
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://fpsCamera.nut");

    fpsCamera.start();

    setupGui();
    ::setDemoType(DemoTypes.DATA_TO_VOX);

    _camera.setPosition(20, 20, 40);
    //_camera.lookAt(0, 0, 0);

    ::count <- 0.0;
}

function update(){
    fpsCamera.update();

    ::currentDemo.update();
}

function end(){

}