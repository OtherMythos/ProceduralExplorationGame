::CharacterModel <- class{
    mModelType_ = CharacterModelType.NONE;
    mParentNode_ = null;
    mNodes_ = null;
    mEquipNodes_ = null;
    mRenderQueue_ = 0;
    mQueryFlag_ = 0;

    mCurrentAnimations_ = null;

    constructor(modelType, parent, nodes, equipNodes, renderQueue=0, queryFlag=0){
        mModelType_ = modelType;
        mParentNode_ = parent;
        mNodes_ = nodes;
        mEquipNodes_ = equipNodes;
        mRenderQueue_ = renderQueue;
        mQueryFlag_ = queryFlag;

        mCurrentAnimations_ = {};
    }

    function destroy(){
        mCurrentAnimations_.clear();
        mParentNode_.destroyNodeAndChildren();
    }

    function setOrientation(orientation){
        mParentNode_.setOrientation(orientation);
    }

    function startAnimation(animId){
        //local newAnim = _animation.createAnimation(animName, mNodes_);
        //local newAnim = _animation.createAnimation(animName, mNodes_);
        local newAnim = createAnimation(animId);
        mCurrentAnimations_.rawset(animId, newAnim);
        resetAnimTimes_();
    }
    function stopAnimation(animId){
        mCurrentAnimations_.rawdelete(animId);
    }
    function resetAnimTimes_(){
        foreach(c,i in mCurrentAnimations_){
            i.setTime(0);
        }
    }

    function createAnimation(animId){
        local target = ::CharacterModelAnims[animId];
        local targetIds = ::ModelTypes[mModelType_].mNodeIds;
        local targetNodes = [];
        foreach(i in target.mUsedNodes){
            if(!targetIds.rawin(i)){
                throw "Missing model type for animation";
            }
            targetNodes.append(mNodes_[targetIds[i]]);
        }
        assert(target.mUsedNodes.len() == targetNodes.len());

        local animationInfo = _animation.createAnimationInfo(targetNodes);
        return _animation.createAnimation(target.mName, animationInfo);
    }

    function equipToNode(item, targetNodeType){
        if(!mEquipNodes_.rawin(targetNodeType)) return;
        local targetNode = mEquipNodes_[targetNodeType];
        targetNode.recursiveDestroyChildren();

        if(item == null) return;
        local meshName = item.getMesh();
        if(meshName == null) throw format("Item '%s' does not define a mesh.", item.getName());

        local model = _scene.createItem(meshName);
        local offsetPos = item.getEquippablePosition();
        local offsetOrientation = item.getEquippableOrientation();
        local offsetScale = item.getEquippableScale();
        local attachNode = targetNode;
        local secondTarget = targetNode;
        if(targetNodeType == CharacterModelEquipNodeType.RIGHT_HAND){
            secondTarget = secondTarget.createChildSceneNode();
            secondTarget.setOrientation(Quat(PI, Vec3(0, 1, 0)));
            attachNode = secondTarget;
        }
        if(offsetPos != null || offsetOrientation != null || offsetScale != null){
            local childNode = secondTarget.createChildSceneNode();
            childNode.setPosition(offsetPos != null ? offsetPos : Vec3());
            childNode.setScale(offsetScale != null ? offsetScale : Vec3(1, 1, 1));
            childNode.setOrientation(offsetOrientation != null ? offsetOrientation : Quat());

            attachNode = childNode;
        }

        model.setRenderQueueGroup(mRenderQueue_);
        attachNode.attachObject(model);
    }
};