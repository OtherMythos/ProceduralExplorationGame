::GuiWidgets.ProgressBar <- class{
    mParentWin_ = null;

    mSize_ = null;
    mPos_ = null;
    mPercentage_ = 0.0;
    mBorder_ = 5;

    mLabel_ = null;
    mLabelObject_ = null;

    mParentContainer_ = null;
    mChildBar_ = null;

    constructor(parent){
        mParentWin_ = parent;
        mSize_ = Vec2(200, 40);

        mParentContainer_ = parent.createPanel();
        mParentContainer_.setSize(mSize_);
        mParentContainer_.setDatablock("gui/progressBarBackground");

        mChildBar_ = parent.createPanel();
        mChildBar_.setSize(mSize_);
        mChildBar_.setDatablock("gui/progressBarRed");

        mParentContainer_.setClickable(false);
        mChildBar_.setClickable(false);

        setPercentage(0.0);
        setPosition(0, 0);
    }

    function setLabel(label){
        mLabel_ = label;
        if(mLabelObject_ == null){
            _constructLabel();
        }
        mLabelObject_.setText(mLabel_);
    }

    function setZOrder(zOrder){
        mParentContainer_.setZOrder(zOrder);
        mChildBar_.setZOrder(zOrder);
    }

    function _constructLabel(){
        mLabelObject_ = mParentWin_.createLabel();
        positionLabel_();
    }

    function addToLayout(layout){
        layout.addCell(mParentContainer_);
    }

    function destroy(){
        _gui.destroy(mParentContainer_);
        _gui.destroy(mChildBar_);
        if(mLabelObject_){
            _gui.destroy(mLabelObject_);
        }
    }

    function positionLabel_(){
        if(mLabelObject_ == null) return;
        local sizeDiv = mSize_ / 2;
        mLabelObject_.setCentre(sizeDiv + mPos_);
    }

    function getPosition(){
        return mParentContainer_.getPosition();
    }
    function setPosition(x, y){
        local pos = Vec2(x, y);
        mParentContainer_.setPosition(pos);
        mChildBar_.setPosition(pos + Vec2(mBorder_, mBorder_));
        positionLabel_();
        mPos_ = pos;
    }
    function setCentre(x, y){
        setPosition(x - mSize_.x / 2, y - mSize_.y / 2);
    }
    function getCentre(){
        return mParentContainer_.getCentre();
    }
    function getDerivedCentre(){
        return mParentContainer_.getDerivedCentre();
    }

    function setSize(x, y){
        mSize_ = Vec2(x, y);
        processSize_();
    }

    function getSize(){
        return mSize_;
    }

    function processSize_(){
        mParentContainer_.setSize(mSize_);
        local intendedSize = mSize_ - Vec2(mBorder_ * 2, mBorder_ * 2);
        mChildBar_.setSize(intendedSize.x * mPercentage_, intendedSize.y);
        positionLabel_();
    }

    function setVisible(visible){
        mParentContainer_.setHidden(!visible);
        mChildBar_.setHidden(!visible);
    }

    function setPercentage(percentage){
        mPercentage_ = percentage;
        processSize_();
    }

    function setBorder(border){
        mBorder_ = border;
        processSize_();
        //setPosition_();
    }

    function notifyLayout(){
        local parentPos = mParentContainer_.getPosition();
        setPosition(parentPos.x, parentPos.y);
    }
};