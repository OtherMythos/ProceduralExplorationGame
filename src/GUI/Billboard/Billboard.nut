enum BillboardZOrder{
    HEALTH_BAR = 70,
    BUTTON = 75
};

::BillboardManager.Billboard <- class{

    mPanel_ = null;
    mSize_ = null;
    mVisible_ = true;
    mMask_ = 0xFFFFFFFF;

    constructor(parent, mask){
        mMask_ = mask;
    }

    function destroy(){
        _gui.destroy(mPanel_);
    }

    function posVisible(pos){
        return true;
    }

    function setPosition(pos){
        mPanel_.setCentre(pos);
    }

    function setVisible(visible){
        mVisible_ = visible;
        mPanel_.setVisible(visible);
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mPanel_.setVisible(false);
        }
    }

    function setMaskVisible(mask){
        mPanel_.setVisible(mVisible_ && (mask & mMask_) != 0);
    }

}