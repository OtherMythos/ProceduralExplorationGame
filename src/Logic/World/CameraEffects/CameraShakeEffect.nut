//Screen shake camera effect that shakes the camera node.
::CameraShakeEffect <- class extends ::CameraEffect{

    mShakeMagnitude_ = 0;
    mShakeDuration_ = 0;
    mShakeCounter_ = 0;
    mShakeFrequency_ = 0;
    mOriginalPosition_ = null;

    constructor(cameraEffectManager, animationNode, params){
        base.constructor(cameraEffectManager, animationNode, params);
        mShakeMagnitude_ = params.magnitude;
        mShakeDuration_ = params.duration;
        mShakeCounter_ = 0;
        mShakeFrequency_ = params.frequency;
        mOriginalPosition_ = animationNode.getPositionVec3();
    }

    function update(){
        if(mShakeCounter_ >= mShakeDuration_){
            //Effect is complete, reset position and return true.
            mAnimationNode_.setPosition(mOriginalPosition_);
            return true;
        }

        //Calculate shake offset based on time and frequency.
        local shakePhase = (mShakeCounter_.tofloat() / mShakeFrequency_.tofloat()) * 2 * PI;
        local decay = 1.0 - (mShakeCounter_.tofloat() / mShakeDuration_.tofloat());

        //Generate shake offsets using sine waves at different phases for x, y, z.
        local offsetX = sin(shakePhase) * mShakeMagnitude_ * decay;
        local offsetY = sin(shakePhase + PI / 3) * mShakeMagnitude_ * decay;
        local offsetZ = sin(shakePhase + 2 * PI / 3) * mShakeMagnitude_ * decay;

        //Apply offset to the animation node.
        local shakePos = mOriginalPosition_.copy();
        shakePos.x += offsetX;
        shakePos.y += offsetY;
        shakePos.z += offsetZ;

        mAnimationNode_.setPosition(shakePos);
        print(shakePos);

        mShakeCounter_++;
        return false;
    }

    function destroy(){
        //Reset position when effect is destroyed.
        if(mAnimationNode_ != null){
            mAnimationNode_.setPosition(mOriginalPosition_);
        }
    }

};
