::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer.ExplorationFoundItemWidget <- class{

    mParent_ = null;
    mRenderedIcon_ = null;
    mPosition_ = null;
    mSize_ = null;

    constructor(parentWin){
        mParent_ = parentWin;
        mPosition_ = Vec2();
        mSize_ = Vec2(100, 100);
    }

    function deactivate(){
        if(mRenderedIcon_ == null) return;
        mRenderedIcon_.destroy();
        mRenderedIcon_ = null;
    }

    function setObject(object){
        local renIcon = ::RenderIconManager.createIcon("coinBag.mesh");
        renIcon.setPosition(mPosition_);
        renIcon.setSize(mSize_.x);
        mRenderedIcon_ = renIcon;
    }

    function setCentre(buttonPos){
        mPosition_ = buttonPos;
        mRenderedIcon_.setPosition(buttonPos);
    }

    function setSize(buttonSize){
        mSize_ = buttonSize;
        mRenderedIcon_.setSize((mSize_.x / 2) * 0.8);
    }

};