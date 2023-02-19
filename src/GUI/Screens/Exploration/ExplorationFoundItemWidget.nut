::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer.ExplorationFoundItemWidget <- class{

    mParent_ = null;
    mRenderedIcon_ = null;
    mPosition_ = null;
    mSize_ = null;
    mButton_ = null;
    mBus_ = null;
    mObject_ = null;

    constructor(parentWin, buttonId, bus){
        mParent_ = parentWin;
        mPosition_ = Vec2();
        mSize_ = Vec2(100, 100);
        mBus_ = bus;
        mObject_ = ::FoundObject();

        local button = parentWin.createButton();
        button.setText("Empty");
        button.setHidden(true);
        button.setUserId(buttonId);
        button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
        mButton_ = button;
    }

    function deactivate(){
        if(mRenderedIcon_ != null){
            mRenderedIcon_.destroy();
            mRenderedIcon_ = null;
        }

        mButton_.setHidden(true);

        mObject_ = ::FoundObject();
    }

    function setObject(object){
        if(object.isNone()){
            deactivate();
            return;
        }
        mObject_ = object;

        local renIcon = mRenderedIcon_;
        if(renIcon == null){
            renIcon = ::RenderIconManager.createIcon();
        }
        renIcon.setMesh("coinBag.mesh");
        renIcon.setPosition(mPosition_);
        renIcon.setSize(mSize_.x);
        mRenderedIcon_ = renIcon;

        mButton_.setHidden(false);
        mButton_.setText(object.toName(), false);
        mButton_.setHidden(false);
        mButton_.setSkinPack(object.getButtonSkinPack());
        mButton_.setZOrder(200);
    }

    function setCentre(buttonPos){
        mPosition_ = buttonPos;
        setCentre_(mPosition_);
    }

    function setSize(buttonSize){
        mSize_ = buttonSize;
        setSize_(buttonSize);
    }

    function setCentre_(pos){
        mButton_.setCentre(pos);
        if(mRenderedIcon_){
            mRenderedIcon_.setPosition(mButton_.getDerivedCentre());
        }
    }
    function setSize_(size){
        if(mRenderedIcon_) mRenderedIcon_.setSize((mSize_.x / 2) * 0.8);
        mButton_.setSize(size);
    }

    function buttonPressed(widget, action){
        local id = widget.getUserId();
        local foundObj = mObject_;
        assert(foundObj != null);
        local value = {
            "type": foundObj.type,
            "slotIdx": id,
            "buttonCentre": widget.getCentre()
        };
        if(foundObj.type == FoundObjectType.ITEM){
            value.item <- foundObj.obj;
        }
        else if(foundObj.type == FoundObjectType.PLACE){
            value.place <- foundObj.obj;
        }else{
            assert(false);
        }

        mBus_.notifyEvent(ExplorationBusEvents.TRIGGER_ITEM, value);
    }

    function shutdown(){
        if(mRenderedIcon_ != null){
            mRenderedIcon_.destroy();
        }
    }

};