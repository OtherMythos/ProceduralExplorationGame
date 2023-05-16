enum CharacterModelType{
    NONE,
    HUMANOID,
    TEST

    MAX
};


::CharacterGenerator <- class{

    mModelTypes_ = array(CharacterModelType.MAX);

    constructor(){
        _animation.loadAnimationFile("res://../../assets/characterAnimations/testCharacterAnimations.xml");
    }

    function createCharacterModel(parentNode, constructionData){
        local modelNode = parentNode.createChildSceneNode();
        local nodes = populateSceneNodeWithModel_(modelNode, CharacterModelType.HUMANOID);

        local animationInfo = _animation.createAnimationInfo(nodes);
        ::currentAnim <- _animation.createAnimation("walk", animationInfo);

        local model = CharacterModel(modelNode);

        return model;
    }

    function populateSceneNodeWithModel_(parentNode, modelId){
        local model = mModelTypes_[modelId];
        local outNodes = array(model.len(), null);
        foreach(c,i in model){
            local modelNode = parentNode.createChildSceneNode();
            local item = _scene.createItem(i.mMesh);
            modelNode.attachObject(item);
            modelNode.setPosition(i.mPos);
            modelNode.setScale(i.mScale);

            outNodes[c] = modelNode;
        }

        return outNodes;
    }

};