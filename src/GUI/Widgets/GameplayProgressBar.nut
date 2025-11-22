::GuiWidgets.GameplayProgressBar <- class{
    BACKGROUND_COLOUR = ColourValue(0.05, 0.05, 0.05, 0.8);
    BAR_LEVEL_1 = ColourValue(0.9, 0.1, 0.1, 1.0);
    BAR_LEVEL_2 = ColourValue(0.8, 0.6, 0.2, 1.0);

    mParentWin_ = null;

    mSize_ = null;
    mPos_ = null;
    mPercentage_ = 0.0;

    mParentContainer_ = null;
    mChildBar_ = null;

    constructor(parent){
        mParentWin_ = parent;
        mSize_ = Vec2(200, 40);

        mParentContainer_ = parent.createPanel();
        mParentContainer_.setSize(mSize_);
        mParentContainer_.setColour(BACKGROUND_COLOUR);

        mChildBar_ = parent.createPanel();
        mChildBar_.setSize(mSize_);
        mChildBar_.setColour(BAR_LEVEL_1);

        mParentContainer_.setClickable(false);
        mChildBar_.setClickable(false);

        setPercentage(0.0);
    }

    function getDatablock(level){
        if(level < 0){
            return BACKGROUND_COLOUR;
        }
        switch(level){
            case 1:
                return BAR_LEVEL_2;
            case 0:
            default:
                return BAR_LEVEL_1;
        }
    }

    function destroy(){
        _gui.destroy(mParentContainer_);
        _gui.destroy(mChildBar_);
    }

    function setZOrder(zOrder){
        mParentContainer_.setZOrder(zOrder);
        mChildBar_.setZOrder(zOrder);
    }

    function setCentre(x, y){
        mParentContainer_.setCentre(x, y);
        mPos_ = mParentContainer_.getPosition();
        mChildBar_.setPosition(mPos_);
    }

    function setSize(x, y){
        mSize_ = Vec2(x, y);
        processSize_();
    }

    function processSize_(){
        mParentContainer_.setSize(mSize_);
        mChildBar_.setSize(mSize_.x * mPercentage_, mSize_.y);
    }

    function setPercentage(percentage){
        mPercentage_ = percentage;
        processSize_();
    }

    function setVisible(visible){
        mParentContainer_.setHidden(!visible);
        mChildBar_.setHidden(!visible);
    }

    function setLevel(level){
        local target = getDatablock(level);
        local background = getDatablock(level-1);
        mChildBar_.setColour(target);
        mParentContainer_.setColour(background);
    }
};