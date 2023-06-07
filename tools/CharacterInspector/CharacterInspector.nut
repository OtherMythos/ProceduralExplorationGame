//A tool to inspect characters, alter their characteristics, etc.

function start(){

    //TODO get rid of this.
    _animation.loadAnimationFile("res://../../assets/characterAnimations/equippableAnimation.xml");

    _doFile("res://CharacterInspectorHelper.nut");
    ::generateFloorGrid();

    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Content/Equippables.nut");
    _doFile("res://../../src/Content/Items.nut");

    _doFile("res://../../src/Util/VoxToMesh.nut");
    _doFile("res://../../src/Character/CharacterModel.nut");
    _doFile("res://../../src/Character/CharacterModelAnimations.nut");
    _doFile("res://../../src/Character/CharacterGenerator.nut");
    ::CharacterGeneratorPrefix = "res://../../";
    _doFile("res://../../src/Character/CharacterModelTypes.nut");

    _doFile("res://../VoxToMesh/fpsCamera.nut");
    _doFile("res://CharacterInspectorBase.nut");

    ::mBase <- CharacterInspectorBase();
}

function update(){
    ::mBase.update();
}

function end(){

}
