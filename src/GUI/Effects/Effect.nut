::Effect <- class{
    mEffectData_ = null;
    mEffectWin_ = null;
    mEffectSize_ = null;

    constructor(effectData){
        mEffectData_ = effectData;
    }

    function update(){

    }

    function getEffectData(){
        return mEffectData_;
    }

    function shutdown(){
        _gui.destroy(mEffectWin_);
    }
}