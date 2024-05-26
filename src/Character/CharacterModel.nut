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

    #Static
    function ___mapEquipSlotToEquipNode___(slot){
        switch(slot){
            case EquippedSlotTypes.LEFT_HAND:
                return CharacterModelEquipNodeType.LEFT_HAND;
            case EquippedSlotTypes.RIGHT_HAND:
                return CharacterModelEquipNodeType.RIGHT_HAND;
            default:
                return CharacterModelEquipNodeType.NONE;
        }
    }
    #Static
    function ___mapEquipSlotToEquipNodeInactiveWield___(slot){
        local targetSlot = ___mapEquipSlotToEquipNode___(slot);

        if(targetSlot == CharacterModelEquipNodeType.LEFT_HAND || targetSlot == CharacterModelEquipNodeType.RIGHT_HAND){
            targetSlot = CharacterModelEquipNodeType.WEAPON_STORE;
        }

        return targetSlot;
    }

    function equipDataToCharacterModel(data, wieldActive=true){
        clearEquipNodes();
        for(local i = EquippedSlotTypes.NONE+1; i < EquippedSlotTypes.MAX; i++){
            local targetEquipNode = wieldActive ? ::CharacterModel.___mapEquipSlotToEquipNode___(i) : ::CharacterModel.___mapEquipSlotToEquipNodeInactiveWield___(i);
            //local targetEquipNode = ::CharacterModel.___mapEquipSlotToEquipNodeInactiveWield___(i);
            if(targetEquipNode == CharacterModelEquipNodeType.NONE) continue;
            local append = targetEquipNode == CharacterModelEquipNodeType.WEAPON_STORE;
            local targetItem = data.getEquippedItem(i);
            equipToNode(targetItem, targetEquipNode, append);
        }
    }

    function destroy(){
        mCurrentAnimations_.clear();
        mParentNode_.destroyNodeAndChildren();
    }

    function setOrientation(orientation){
        mParentNode_.setOrientation(orientation);
    }

    function startAnimationBaseType(baseAnim){
        local baseAnims = ::ModelTypes[mModelType_].mBaseAnims;
        local anim = baseAnims[baseAnim];
        if(anim == CharacterModelAnimId.NONE) return;
        startAnimation(anim);
    }
    function stopAnimationBaseType(baseAnim){
        local baseAnims = ::ModelTypes[mModelType_].mBaseAnims;
        local anim = baseAnims[baseAnim];
        if(anim == CharacterModelAnimId.NONE) return;
        stopAnimation(anim);
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

    function clearEquipNodes(){
        for(local i = CharacterModelEquipNodeType.NONE+1; i < CharacterModelEquipNodeType.MAX; i++){
            local targetNode = mEquipNodes_[i];
            targetNode.recursiveDestroyChildren();
        }
    }
    function equipToNode(item, targetNodeType, append=false){
        if(!mEquipNodes_.rawin(targetNodeType)) return;
        local targetNode = mEquipNodes_[targetNodeType];
        if(!append){
            targetNode.recursiveDestroyChildren();
        }

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

    function determineAABB(){
        local startAABB = getAABBForNode_(mNodes_, 0);
        for(local i = 1; i < mNodes_.len(); i++){
            local mergeAABB = getAABBForNode_(mNodes_, i);
            if(mergeAABB != null){
                startAABB.merge(mergeAABB);
            }
        }
        return startAABB;
    }
    function getAABBForNode_(nodes, idx){
        local node = nodes[idx];
        local attached = node.getNumAttachedObjects();
        if(attached <= 0) return null;
        local obj = node.getAttachedObject(0);
        return obj.getLocalAabb();
    }
};