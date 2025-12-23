enum BillboardZOrder{
    HEALTH_BAR = 70,
    PLACE_DESCRIPTION = 71,
    BUTTON = 75
};

::BillboardManager.Billboard <- class{

    mPanel_ = null;
    mSize_ = null;
    //Billboards implement three visibility settings
    //mVisible_ is generic visibility, this can be turned off and on for gameplay events.
    mVisible_ = true;
    //mMask_ is used to prevent billboards being drawn in cases like worlds not being active. I the mask does not & match visibility is false.
    mMask_ = 0xFFFFFFFF;
    mCurrentMask_ = 0xFFFFFFFF;
    //mCullVisible_ is used to tell if the billboard is on the screen or not, and should only be used by the billboard manager.
    mCullVisible_ = true;

    constructor(parent, mask){
        mMask_ = mask;
    }

    function destroy(){
        _gui.destroy(mPanel_);
    }

    function setPosition(pos){
        mPanel_.setCentre(pos);
    }

    function setVisible(visible){
        mVisible_ = visible;
        determineVisible_();
    }

    function setMaskVisible(mask){
        mCurrentMask_ = mask;
        determineVisible_();
    }

    function setCullVisible(cull){
        mCullVisible_ = cull;
        determineVisible_();
    }

    function determineVisible_(){
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            mPanel_.setVisible(false);
            return;
        }

        mPanel_.setVisible(mVisible_ && mCullVisible_ && (mCurrentMask_ & mMask_) != 0);
    }

}