::CharacterModel <- class{
    mNode_ = null;
    mAnimInfo_ = null;

    mCurrentAnimations_ = null;

    constructor(node, animationInfo){
        mNode_ = node;
        mAnimInfo_ = animationInfo;

        mCurrentAnimations_ = {};
    }

    function startAnimation(animName){
        local newAnim = _animation.createAnimation(animName, mAnimInfo_);
        mCurrentAnimations_.rawset(animName, newAnim);
    }
    function stopAnimation(animName){
        mCurrentAnimations_.rawdelete(animName);
    }
};