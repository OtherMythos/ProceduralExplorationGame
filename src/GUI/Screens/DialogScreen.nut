::DialogScreen <- class extends ::Screen{

    mTextContainer_ = null;
    mNextDialogButton_ = null;

    constructor(){

    }

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

    function setup(){
        _event.subscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.subscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);

        //Create a window to block inputs for when the popup appears.
        mWindow_ = _gui.createWindow();
        local winSize = Vec2(_window.getWidth(), _window.getHeight() * 0.3333);
        mWindow_.setSize(winSize);
        mWindow_.setPosition(0, _window.getHeight() * 0.6666);

        mTextContainer_ = mWindow_.createLabel();
        mTextContainer_.setText(" ");

        mNextDialogButton_ = mWindow_.createButton();
        mNextDialogButton_.setText("Next");
        mNextDialogButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);

        local buttonSize = mNextDialogButton_.getSize();
        buttonSize *= 2;
        mNextDialogButton_.setPosition(winSize.x - buttonSize.x, winSize.y - buttonSize.y);

        setDialogVisible(false);
        mWindow_.setZOrder(200);
    }

    function shutdown(){
        base.shutdown();

        _event.unsubscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.unsubscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
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