enum CharacterModelType{
    NONE,
    HUMANOID,
    TEST

    MAX
};

enum CharacterModelEquipNodeType{
    LEFT_HAND,
    RIGHT_HAND
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
        local animationInfo = _animation.createAnimationInfo(nodes[0]);

        local model = CharacterModel(modelNode, animationInfo, nodes[1]);
        modelNode.setScale(0.3, 0.3, 0.3);

        //model.startAnimation("HumanoidFeetWalk");
        //model.startAnimation("HumanoidUpperWalk");

        return model;
    }

    function populateSceneNodeWithModel_(parentNode, modelDef){
        local model = modelDef.mNodes;
        local outNodes = array(model.len(), null);
        local equipNodes = {};
        foreach(c,i in model){
            local modelNode = parentNode.createChildSceneNode();
            if(i.mMesh){
                local item = _scene.createItem(i.mMesh);
                modelNode.attachObject(item);
            }
            if(i.mPos) modelNode.setPosition(i.mPos);
            if(i.mScale) modelNode.setScale(i.mScale);

            outNodes[c] = modelNode;

            //For now assume these are just the equip nodes, so no recursion needed.
            if(i.mChildren){
                foreach(e in i.mChildren){
                    if(e.mEquipType == null) continue;
                    local modelNode = modelNode.createChildSceneNode();
                    if(e.mPos) modelNode.setPosition(e.mPos);
                    if(e.mScale) modelNode.setScale(e.mScale);
                    equipNodes.rawset(e.mEquipType, modelNode);
                }
            }
        }

        return [outNodes, equipNodes];
    }

};