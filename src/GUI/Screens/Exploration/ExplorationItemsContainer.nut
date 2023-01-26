::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationItemsContainer <- class{
    mWindow_ = null;
    mPanel_ = null;
    mSizerPanels_ = null;
    mButtons_ = null;
    mFoundObjects_ = null;
    mBus_ = null;
    mBackground_ = null;
    mAnimator_ = null;

    mWidth_ = 0;
    mButtonSize_ = 0;

    mNumSlots_ = 4;

    mLayoutLine_ = null;

    constructor(parentWin, bus){
        mAnimator_ = ExplorationItemsContainerAnimator(this);

        mWidth_ = _window.getWidth() * 0.9;
        mButtonSize_ = mWidth_ / 5;
        mBus_ = bus;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow(parentWin);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setHidden(true);
        mWindow_.setClickable(false);

        mBackground_ = parentWin.createPanel();
        mBackground_.setSkin("internal/WindowSkin");

        mLayoutLine_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);
        mButtons_ = array(mNumSlots_);
        mSizerPanels_ = array(mNumSlots_);
        mFoundObjects_ = array(mNumSlots_, null);

        //These widgets just leverage the sizer functionality to position the parent buttons.
        for(local i = 0; i < mNumSlots_; i++){
            local button = mWindow_.createPanel();
            button.setClickable(false);
            button.setExpandVertical(true);
            button.setExpandHorizontal(true);
            button.setProportionHorizontal(1);
            mLayoutLine_.addCell(button);
            mSizerPanels_[i] = button;
        }
        for(local i = 0; i < mNumSlots_; i++){
            local button = parentWin.createButton();
            button.setText("Empty");
            button.setHidden(true);
            button.setUserId(i);
            button.attachListenerForEvent(buttonPressed, _GUI_ACTION_PRESSED, this);
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
        local sizerButton = mSizerPanels_[index];
        button.setPosition(mWindow_.getPosition() + sizerButton.getPosition());
        button.setZOrder(200);
        button.setSize(sizerButton.getSize());

        button.setText(object.toName(), false);
        button.setHidden(false);
        button.setSkinPack(object.getButtonSkinPack());
        mFoundObjects_[index] = object;
    }

    function update(){
        mAnimator_.update(mButtons_, mFoundObjects_);
    }

    function sizeForButtons(){
        //Actually sizing up the buttons has to be delayed until the window has its size.
        mLayoutLine_.setSize(mWindow_.getSize());
        mLayoutLine_.layout();

        mBackground_.setPosition(mWindow_.getPosition());
        mBackground_.setSize(mWindow_.getSize());
    }
};

_doFile("res://src/GUI/Screens/Exploration/ExplorationItemsContainerAnimator.nut");