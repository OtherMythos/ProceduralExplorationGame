//A tool to inspect characters, alter their characteristics, etc.

function start(){
    parseProjectOgreResources();

    //local winSize = Vec2(_window.getWidth(), _window.getHeight());
    //_gui.setCanvasSize(winSize, winSize);

    //TODO get rid of this.
    _animation.loadAnimationFile("res://../../assets/characterAnimations/equippableAnimation.xml");

    _doFile("res://CharacterInspectorHelper.nut");
    ::generateFloorGrid();

    _doFile("res://../../src/System/EnumDef.nut");
    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Helpers.nut");
    _doFile("res://../../src/Content/Equippables.nut");
    _doFile("res://../../src/Content/Items.nut");
    _doFile("res://../../src/Content/ItemEnums.nut");
    ::EnumDef.commitEnums();
    _doFile("res://../../src/Content/ItemDefs.nut");

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
    ::mBase.saveCurrentSettings();
}

function parseProjectOgreResources(){
    local FILE_PATH = "res://../../OgreResources.cfg";
    if(_system.exists(FILE_PATH)){
        _resources.destroyResourceGroup("General");
        _resources.parseOgreResourcesFile(FILE_PATH);
        _resources.initialiseAllResourceGroups();
    }else{
        throw "Could not find Ogres resources file for the parent project";
    }
}
