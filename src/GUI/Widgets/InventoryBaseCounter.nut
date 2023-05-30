::GuiWidgets.InventoryBaseCounter <- class{
    mLabel_ = null;
    mBaseLabel_ = "Base";

    mCurrentAnim_ = 0;
    mAnimTo_ = 0;
    mAnimating_ = false;

    constructor(parent){
        setup(parent);
    }

    function setup(parent){
        mLabel_ = parent.createLabel();
        mAnimTo_ = mCurrentAnim_;
        setLabelTo(mCurrentAnim_);

    }
    function shutdown(){

    }

    function setLabelTo(moneyVal){
        mLabel_.setText(format("%s: %i", mBaseLabel_, moneyVal));
    }

    function addToLayout(layout){
        layout.addCell(mLabel_);
    }

    function addForAnimation(amount){
        mAnimTo_ += amount;
        mAnimating_ = true;
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
};