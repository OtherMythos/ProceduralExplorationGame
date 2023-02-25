::Effect <- class{
    mEffectData_ = null;
    mEffectSize_ = null;

    mLifetimeCount_ = 0;
    mTotalLifetimeCount_ = 10;

    constructor(effectData){
        mEffectData_ = effectData;
    }

    function update(){

    }

    function getEffectData(){
        return mEffectData_;
    }

    function tickLifetime(){
        mLifetimeCount_++;
        return mLifetimeCount_ < mTotalLifetimeCount_;
    }

    function getCurrentPercentage(){
        return mLifetimeCount_.tofloat() / mTotalLifetimeCount_.tofloat();
    }

    function _tostring(){
        return ::wrapToString(this, "Effect", mEffectIdx_.tostring());
    }
}