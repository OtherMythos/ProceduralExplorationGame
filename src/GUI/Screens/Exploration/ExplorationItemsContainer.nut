::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer <- class{
    mWindow_ = null;
    mPanel_ = null;
    mButtons_ = null;
    mFoundObjects_ = null;
    mBus_ = null;

    mWidth_ = 0;
    mButtonSize_ = 0;

    mNumSlots_ = 4;

    mLayoutLine_ = null;

    constructor(parentWin, bus){
        mWidth_ = _window.getWidth() * 0.9;
        mButtonSize_ = mWidth_ / 5;
        mBus_ = bus;

        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mLayoutLine_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mButtons_ = array(mNumSlots_);
        mFoundObjects_ = array(mNumSlots_, null);

        for(local i = 0; i < mNumSlots_; i++){
            local button = mWindow_.createButton();
            button.setText("Empty");
            button.setHidden(true);
            button.setUserId(i);
            button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
            button.setExpandVertical(true);
            button.setExpandHorizontal(true);
            button.setProportionHorizontal(1);
            mLayoutLine_.addCell(button);
            mButtons_[i] = button;
        }
        mLayoutLine_.setMarginForAllCells(10, 10);
    }

    function buttonPressed(widget, action){
        local id = widget.getUserId();
        local foundObj = mFoundObjects_[id];
        local value = {
            "type": foundObj.type,
            "slotIdx": id
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

    function addToLayout(layoutLine){
        layoutLine.addCell(mWindow_);
        mWindow_.setExpandVertical(true);
        mWindow_.setExpandHorizontal(true);
        mWindow_.setProportionVertical(1);
    }

    function setObjectForIndex(object, index){
        assert(index < mButtons_.len());
        local button = mButtons_[index];
        if(object.isNone()){
            button.setHidden(true);
            return;
        }
        button.setText(object.toName(), false);
        button.setHidden(false);
        button.setSkinPack(object.getButtonSkinPack());
        mFoundObjects_[index] = object;
    }

    function sizeForButtons(){
        //Actually sizing up the buttons has to be delayed until the window has its size.
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();
    }
};