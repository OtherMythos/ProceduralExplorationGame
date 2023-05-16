//Just demonstrate an example of the voxel tool in use.

function start(){
    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Character/CharacterModel.nut");
    _doFile("res://../../src/Character/CharacterGenerator.nut");
    _doFile("res://../../src/Character/CharacterModelTypes.nut");

    _doFile("res://../VoxToMesh/fpsCamera.nut");


    fpsCamera.start(Vec3());

    ::generator <- CharacterGenerator();

    local constructionData = {
        "test": null
    };

    local targetNode = _scene.getRootSceneNode().createChildSceneNode();
    local model = ::generator.createCharacterModel(targetNode, constructionData);

    _camera.setPosition(0, 0, 20);
    _camera.lookAt(0, 0, 0);
}

function update(){

    fpsCamera.update();
}

function end(){

}