function start(){
    _doFile("res://../../src/Constants.nut");
    _doFile("res://../../src/Helpers.nut");

    _doFile("res://../../src/Character/CharacterModelAnimations.nut");
    _doFile("res://../../src/Character/CharacterModel.nut");
    _doFile("res://../../src/Character/CharacterGenerator.nut");
    _doFile("res://../../src/Character/CharacterModelTypes.nut");

    _doFile("res://CharacterDumper.nut");

    ::CharacterDumper.dump("res://../../.dumpedCharacterModels");
    ::AnimationDumper.dump("res://../../.dumpedCharacterAnimations");

    _shutdownEngine();
}
