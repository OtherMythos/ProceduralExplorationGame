::GuiWidgets.InventoryBaseCounter <- class{
    mLabel_ = null;
    mBaseLabel_ = "Base";
    mParentObj_ = null;

    mCurrentAnim_ = 0;
    mAnimTo_ = 0;

    constructor(parent){
        setup(parent);
    }

    function setup(parent, parentObj=null){
        mLabel_ = parent.createLabel();
        mLabel_.setMargin(10, 10);
        mLabel_.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
        mAnimTo_ = mCurrentAnim_;
        setLabelTo(mCurrentAnim_);

        mParentObj_ = parentObj;
    }
    function shutdown(){

    }

    function setLabelTo(moneyVal){
        mLabel_.setText(format("%s: %i", mBaseLabel_, moneyVal));
        if(mParentObj_ != null){
            mParentObj_.notifyCounterChanged();
        }
    }

    function addToLayout(layout){
        layout.addCell(mLabel_);
    }

    function addForAnimation(amount){
        mAnimTo_ += amount;
    }

    function setValueCancelAnim(value){
        mAnimTo_ = value;
        mCurrentAnim_ = value;
        setLabelTo(value);
    }

    function getPositionWindowPos(){
        return ::EffectManager.getWorldPositionForWindowPos(mLabel_.getDerivedCentre());
    }

    function update(){
        if(mAnimTo_ > mCurrentAnim_){
            mCurrentAnim_+=4;
            if(mCurrentAnim_ > mAnimTo_){
                mCurrentAnim_ = mAnimTo_;
            }
            setLabelTo(mCurrentAnim_);
        }
    }

    function getSize(){
        return mLabel_.getSize();
    }

    function getPosition(){
        return mLabel_.getPosition();
    }

    function setPosition(pos){
        mLabel_.setPosition(pos);
    }
};