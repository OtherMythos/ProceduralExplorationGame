//Just demonstrate an example of the voxel tool in use.

function start(){
    _doFile("res://../../src/Util/VoxToMesh.nut");

    local voxMesh = VoxToMesh();

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

    local meshObj = voxMesh.createMeshForVoxelData("testVox", voxData, width, height, depth);

    local item = _scene.createItem(meshObj);
    local newNode = _scene.getRootSceneNode().createChildSceneNode();
    newNode.attachObject(item);

    _camera.setPosition(0, 0, 20);
    _camera.lookAt(0, 0, 0);

    ::count <- 0.0;
}

function update(){
    return;
    ::count += 0.01;
    _camera.setPosition(sin(count) * 20, 0, cos(count) * 20);
    _camera.lookAt(0, 0, 0);
}

function end(){

}