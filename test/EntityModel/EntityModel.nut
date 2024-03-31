_t("testEntityModels", "Iterate through all entity models, generating an instance of each to check all the models exist properly.", function(){
    local gen = ::CharacterGenerator();

    _camera.setPosition(0, 0, -20);
    _camera.lookAt(0, 0, 0);

    for(local i = CharacterModelType.NONE+1; i < CharacterModelType.MAX; i++){
        local modelNode = _scene.getRootSceneNode().createChildSceneNode();
        gen.createCharacterModel(modelNode, {"type": i});
        modelNode.destroyNodeAndChildren();
    }
});