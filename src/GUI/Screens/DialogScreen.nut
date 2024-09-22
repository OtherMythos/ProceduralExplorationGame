::ScreenManager.Screens[Screen.DIALOG_SCREEN] = class extends ::Screen{

    mTextContainer_ = null;
    mNextDialogButton_ = null;

    function receiveDialogSpokenEvent(id, data){
        setNewDialogText(data);
    }

    function receiveDialogMetaEvent(id, data){
        if("ended" in data && data.ended){
            setDialogVisible(false);
        }

        if("started" in data && data.started){
            setDialogVisible(true);
        }
    }

    function nextButtonPressed(widget, action){
        ::Base.mDialogManager.notifyProgress();
    }

    function setup(data){
        base.setup(data);

        _event.subscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.subscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
    }

    function shutdown(){
        base.shutdown();

        _event.unsubscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.unsubscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
    }

    function recreate(){

        //Create a window to block inputs for when the popup appears.
        mWindow_ = _gui.createWindow("DialogScreen");
        //local winSize = Vec2(_window.getWidth(), _window.getHeight() * 0.3333);
        //mWindow_.setSize(winSize);
        //mWindow_.setPosition(0, _window.getHeight() * 0.6666);

        mWindow_.setSize(::drawable);

        mTextContainer_ = mWindow_.createLabel();
        mTextContainer_.setText(" ");

        mNextDialogButton_ = mWindow_.createButton();
        mNextDialogButton_.setText("Next");
        mNextDialogButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);

        local buttonSize = mNextDialogButton_.getSize();
        //buttonSize *= 2;
        local winSize = mWindow_.getSizeAfterClipping();
        mNextDialogButton_.setPosition(winSize.x - buttonSize.x, winSize.y - buttonSize.y);

        setDialogVisible(false);
    }

    function setNewDialogText(textData){
        mTextContainer_.setText(textData, false);
        local winSize = mWindow_.getSize();
        mTextContainer_.sizeToFit(winSize.x * 0.9);
    }

    function setDialogVisible(visible){
        print("Setting dialog screen visible: " + visible.tostring());
        mWindow_.setHidden(!visible);
    }
}