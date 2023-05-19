enum CharacterModelType{
    NONE,
    HUMANOID,
    TEST

    MAX
};


::CharacterGenerator <- class{

    mModelTypes_ = array(CharacterModelType.MAX);

    constructor(){
    }

    function createCharacterModel(parentNode, constructionData){

        local modelDef = mModelTypes_[CharacterModelType.HUMANOID];

        //TODO have some system to manage the animation file lifetimes.
        _animation.loadAnimationFile(modelDef.mAnimFile);

        local modelNode = parentNode.createChildSceneNode();
        local nodes = populateSceneNodeWithModel_(modelNode, modelDef);
        local animationInfo = _animation.createAnimationInfo(nodes);

        local model = CharacterModel(modelNode, animationInfo);
        modelNode.setScale(0.3, 0.3, 0.3);

        //model.startAnimation("HumanoidFeetWalk");
        //model.startAnimation("HumanoidUpperWalk");

        return model;
    }

    function populateSceneNodeWithModel_(parentNode, modelDef){
        local model = modelDef.mNodes;
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