::GuiWidgets.TwoBarProgressBar <- class extends ::GuiWidgets.ProgressBar{
    SECONDARY_BAR_DATABLOCK = "gui/progressBarYellow";

    mSecondaryBar_ = null;
    mSecondaryPercentage_ = 0.0;

    constructor(parent){
        base.constructor(parent);

        local secondaryBar = parent.createPanel();
        secondaryBar.setSize(mSize_);
        secondaryBar.setDatablock(SECONDARY_BAR_DATABLOCK);
        secondaryBar.setClickable(false);

        mSecondaryBar_ = mChildBar_;
        mChildBar_ = secondaryBar;

        mChildBar_.setDatablock(BAR_DATABLOCK);
        mSecondaryBar_.setDatablock(SECONDARY_BAR_DATABLOCK);

        setPercentage(0.0);
        setSecondaryPercentage(0.0);
        setPosition(0, 0);
    }

    function setZOrder(zOrder){
        base.setZOrder(zOrder);
        mSecondaryBar_.setZOrder(zOrder);
    }

    function destroy(){
        base.destroy();
        _gui.destroy(mSecondaryBar_);
    }

    function setPosition(x, y){
        base.setPosition(x, y);
        if(mSecondaryBar_ != null){
            mSecondaryBar_.setPosition(Vec2(x, y) + Vec2(mBorder_, mBorder_));
        }
    }
    function processSize_(){
        base.processSize_();
        if(mSecondaryBar_ != null){
            local intendedSize = mSize_ - Vec2(mBorder_ * 2, mBorder_ * 2);
            mSecondaryBar_.setSize(intendedSize.x * mSecondaryPercentage_, intendedSize.y);
        }
    }

    function setVisible(visible){
        base.setVisible(visible);
        mSecondaryBar_.setHidden(!visible);
    }

    function setSecondaryPercentage(percentage){
        mSecondaryPercentage_ = percentage;
        processSize_();
    }

    function getDerivedCentre(){
        return mSecondaryBar_.getDerivedCentre();
    }
};