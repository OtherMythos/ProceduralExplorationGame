::CharacterModel <- class{
    mNode_ = null;
    mAnimInfo_ = null;
    mEquipNodes_ = null;
    mRenderQueue_ = 0;

    mCurrentAnimations_ = null;

    constructor(node, animationInfo, equipNodes, renderQueue=0){
        mNode_ = node;
        mAnimInfo_ = animationInfo;
        mEquipNodes_ = equipNodes;
        mRenderQueue_ = renderQueue;

        mCurrentAnimations_ = {};
    }

    function setOrientation(orientation){
        mNode_.setOrientation(orientation);
    }

    function startAnimation(animName){
        local newAnim = _animation.createAnimation(animName, mAnimInfo_);
        mCurrentAnimations_.rawset(animName, newAnim);
        resetAnimTimes_();
    }
    function stopAnimation(animName){
        mCurrentAnimations_.rawdelete(animName);
    }
    function resetAnimTimes_(){
        foreach(c,i in mCurrentAnimations_){
            i.setTime(0);
        }
    }

    function equipToNode(item, targetNode){
        if(!mEquipNodes_.rawin(targetNode)) return;
        local targetNode = mEquipNodes_[targetNode];
        targetNode.recursiveDestroyChildren();

        if(item == null) return;

        local model = _scene.createItem(item.getMesh());
        local offsetPos = item.getEquippablePosition();
        local offsetOrientation = item.getEquippableOrientation();
        local attachNode = targetNode;
        if(offsetPos != null || offsetOrientation != null){
            local childNode = targetNode.createChildSceneNode();
            childNode.setPosition(offsetPos != null ? offsetPos : Vec3());
            childNode.setOrientation(offsetOrientation != null ? offsetOrientation : Quat());

            attachNode = childNode;
        }

        model.setRenderQueueGroup(mRenderQueue_);
        attachNode.attachObject(model);
    }
};