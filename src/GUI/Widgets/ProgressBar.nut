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

    BACKGROUND_DATABLOCK = "gui/progressBarBackground";
    BAR_DATABLOCK = "gui/progressBarRed";

    BACKGROUND_COLOUR = ColourValue(0.05, 0.05, 0.05, 1.0);
    BAR_COLOUR = ColourValue(0.9, 0.1, 0.1, 1.0);

    constructor(parent){
        mParentWin_ = parent;
        mSize_ = Vec2(200, 40);

        mParentContainer_ = parent.createPanel();
        mParentContainer_.setSize(mSize_);
        mParentContainer_.setColour(BACKGROUND_COLOUR);

        mChildBar_ = parent.createPanel();
        mChildBar_.setSize(mSize_);
        mChildBar_.setColour(BAR_COLOUR);

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
        positionLabel_();
    }

    function setLabelShadow(colour, offset=null){
        if(mLabelObject_ == null){
            throw "Label does not exist";
        }
        if(colour == null){
            mLabelObject_.setShadowOutline(false);
            return;
        }
        mLabelObject_.setShadowOutline(true, colour, offset);
    }

    function setColour(colour){
        mParentContainer_.setColour(ColourValue(0.05, 0.05, 0.05, colour.a));
        mChildBar_.setColour(ColourValue(0.9, 0.1, 0.1, colour.a));
        if(mLabelObject_ != null){
            mLabelObject_.setColour(colour);
        }
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
    function getDerivedPosition(){
        return mParentContainer_.getDerivedPosition();
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

    function setMinSize(size){
        mParentContainer_.setMinSize(size);
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
        mSize_ = mParentContainer_.getSize();

        local parentPos = mParentContainer_.getPosition();
        setPosition(parentPos.x, parentPos.y);

        processSize_();
    }
};