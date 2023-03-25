//Just demonstrate an example of the voxel tool in use.

function start(){
    _doFile("res://../../src/Util/VoxToMesh.nut");

    local voxMesh = VoxToMesh();

    local width = 10;
    local height = 10;
    local depth = 10;
    local voxData = array(width * height * depth, 0);
    //voxData[5 + (1*width) + (1*width*height)] = 1;
    voxData[0] = 1;
    voxData[1] = 1;
    voxData[3] = 1;
    //voxData[5 + (2*width) + (1*width*height)] = 1;
    //voxData[5 + (3*width) + (1*width*height)] = 1;
    //voxData[5 + (4*width) + (1*width*height)] = 1;

    ::meshObj <- voxMesh.createMeshForVoxelData("testVox", voxData, width, height, depth);

    _camera.setPosition(0, 0, 20);
    _camera.lookAt(0, 0, 0);

    ::count <- 0.0;
}

function update(){
    ::count += 0.01;
    meshObj.setOrientation(Quat(count, Vec3(0, 1, 0)));
}

function end(){

}