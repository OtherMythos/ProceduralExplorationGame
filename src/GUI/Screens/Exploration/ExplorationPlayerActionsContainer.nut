::ScreenManager.Screens[Screen.EXPLORATION_SCREEN].ExplorationPlayerActionsContainer <- class{
    mParent_ = null;
    mWindow_ = null;
    mLayoutLine_ = null;
    mLabels_ = null;

    mTouchInterface_ = null;

    constructor(parentWin, parent, touchInterface=false){
        mParent_ = parent;
        mTouchInterface_ = touchInterface;

        //The window is only responsible for laying things out.
        mWindow_ = _gui.createWindow("ExplorationPlayerActions", parentWin);
        mWindow_.setClickable(false);
        mWindow_.setSkin("internal/WindowNoBorder");
        mWindow_.setVisualsEnabled(false);

        mLabels_ = array(ACTION_MANAGER_NUM_SLOTS);

        mLayoutLine_ = _gui.createLayoutLine();

        for(local i = 0; i < ACTION_MANAGER_NUM_SLOTS; i++){
            local label = null;
            if(mTouchInterface_){
                label = mWindow_.createButton();
                label.setUserId(i);
                label.attachListenerForEvent(actionButtonPressed, _GUI_ACTION_PRESSED);
                label.setDefaultFontSize(label.getDefaultFontSize() * 1.2);
            }else{
                label = mWindow_.createLabel();
                label.setDefaultFontSize(label.getDefaultFontSize() * 1.5);
            }
            mLayoutLine_.addCell(label);
            mLabels_[i] = label;
        }

        _event.subscribe(Event.ACTIONS_CHANGED, actionsChanged, this);
    }

    function actionButtonPressed(widget, action){
        ::Base.mActionManager.executeSlot(widget.getUserId());
    }

    function shutdown(){
        _event.unsubscribe(Event.ACTIONS_CHANGED, actionsChanged, this);
    }

    function setPosition(pos){
        mWindow_.setPosition(pos);
    }
    function getPosition(){
        return mWindow_.getPosition();
    }
    function setSize(width, height){
        mWindow_.setSize(width, height);
    }
    function getSize(){
        return mWindow_.getSize();
    }

    function sizeLayout(){
        mLayoutLine_.layout();
    }

    function actionsChanged(id, data){
        foreach(c,i in data){
            if(i.populated()){
                mLabels_[c].setText(getActionString(c) + i.tostring());
                mLabels_[c].setVisible(true);
            }else{
                mLabels_[c].setText(" ");
                mLabels_[c].setVisible(false);
            }
        }
        reprocessPosition();
    }

    function getActionString(id){
        if(mTouchInterface_){
            return "";
        }
        return "z - ";
    }

    function setVisible(visible){
        mWindow_.setVisible(visible);
    }

    function reprocessPosition(){
        //mWindow_.setSize(100, 100);
        mWindow_.setSize(mWindow_.calculateChildrenSize());
        if(mTouchInterface_){
            mWindow_.setPosition(0, mParent_.getGameplayWindowPosition().y);
        }else{
            mWindow_.setPosition(0, _window.getHeight() - mWindow_.getSize().y);
        }
    }
};
