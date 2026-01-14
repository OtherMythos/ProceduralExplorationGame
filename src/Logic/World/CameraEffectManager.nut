//Base class for camera effects that can be applied to a world.
//Subclasses should override update() to implement their specific effect behaviour.
::CameraEffect <- class{

    mCameraEffectManager_ = null;
    mAnimationNode_ = null;
    mActive_ = true;
    mLifetime_ = 0;

    constructor(cameraEffectManager, animationNode, params){
        mCameraEffectManager_ = cameraEffectManager;
        mAnimationNode_ = animationNode;
    }

    //Called each frame to update the effect.
    //Return true if the effect is complete and should be removed, false otherwise.
    function update(){
        return mActive_;
    }

    //Override to define custom cleanup logic.
    function destroy(){
    }

    function getActive(){
        return mActive_;
    }

    function setActive(active){
        mActive_ = active;
    }

    function getAnimationNode(){
        return mAnimationNode_;
    }

};

//Manages camera effects for a world.
//Effects are stored in a VersionPool and updated each frame.
//The camera's parent node gets an animation child node created for effect animation.
::CameraEffectManager <- class{

    mEffectPool_ = null;
    mCameraAnimationNode_ = null;
    mCamera_ = null;
    mCameraParentNode_ = null;

    constructor(){
        mEffectPool_ = ::VersionPool();
    }

    //Setup the camera effect manager with the exploration camera.
    //This retrieves the parent node of the camera and creates an animation child node.
    function setup(camera){
        mCamera_ = camera;
        //Get the parent node of the camera (the node it's attached to).
        mCameraParentNode_ = camera.getParentNode();
        mCameraParentNode_.detachObject(camera);
        //Create a child node under the parent for animation effects.
        mCameraAnimationNode_ = mCameraParentNode_.createChildSceneNode();
        local innerNode = mCameraAnimationNode_.createChildSceneNode();
        innerNode.attachObject(camera);
    }

    //Add a new camera effect to the manager.
    //Returns the effect ID for later reference.
    function addEffect(effect){
        return mEffectPool_.store(effect);
    }

    //Remove a camera effect by its ID.
    function removeEffect(effectId){
        local effect = mEffectPool_.get(effectId);
        if(effect != null){
            effect.destroy();
        }
        mEffectPool_.unstore(effectId);
    }

    //Update all active camera effects.
    function update(){
        //We need to collect completed effects to remove them.
        local completedEffects = [];

        //Iterate through the pool and update all effects.
        for(local i = 0; i < mEffectPool_.mObject_.len(); i++){
            local effect = mEffectPool_.mObject_[i];
            if(effect != null){
                local effectId = (mEffectPool_.mObjectVersions_[i] << 32) | i;
                if(mEffectPool_.valid(effectId)){
                    local isComplete = effect.update();
                    if(isComplete){
                        completedEffects.append(effectId);
                    }
                }
            }
        }

        //Remove completed effects.
        foreach(effectId in completedEffects){
            removeEffect(effectId);
        }
    }

    function getAnimationNode(){
        return mCameraAnimationNode_;
    }

    function getCamera(){
        return mCamera_;
    }

    function getCameraParentNode(){
        return mCameraParentNode_;
    }

    function shutdown(){
        if(mCameraAnimationNode_ != null){
            mCameraAnimationNode_.destroyNodeAndChildren();
            mCameraAnimationNode_ = null;
        }
        //Don't destroy the parent node as it belongs to the camera system.
        mCameraParentNode_ = null;
        mCamera_ = null;
    }

};
