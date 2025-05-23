
::CharacterGeneratorPrefix <- "res://"
::CharacterGenerator <- class{

    constructor(){
    }

    function createCharacterModel(parentNode, constructionData, renderQueue=0, queryFlag=0, datablock=null){
        local modelType = constructionData.type;
        local modelDef = ::ModelTypes[modelType];

        //TODO have some system to manage the animation file lifetimes.
        _animation.loadAnimationFile(modelDef.mAnimFile);

        local modelNode = parentNode.createChildSceneNode();
        local nodes = populateSceneNodeWithModel_(modelNode, modelDef, renderQueue, queryFlag, datablock);

        local model = CharacterModel(modelType, modelNode, nodes[0], nodes[1], renderQueue, queryFlag);
        modelNode.setScale(0.3, 0.3, 0.3);

        //model.startAnimation("HumanoidFeetWalk");
        //model.startAnimation("HumanoidUpperWalk");

        return model;
    }

    function populateSceneNodeWithModel_(parentNode, modelDef, renderQueue, queryFlag, datablock){
        local model = modelDef.mNodes;
        local outNodes = array(model.len(), null);
        local equipNodes = {};
        foreach(c,i in model){
            local modelNode = parentNode.createChildSceneNode();
            if(i.mMesh){
                local item = _gameCore.createVoxMeshItem(i.mMesh);
                item.setRenderQueueGroup(renderQueue);
                item.setQueryFlags(queryFlag);
                if(datablock != null){
                    item.setDatablock(datablock);
                }
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
                    if(e.mOrientation) modelNode.setOrientation(e.mOrientation);
                    equipNodes.rawset(e.mEquipType, modelNode);
                }
            }
        }

        return [outNodes, equipNodes];
    }

};