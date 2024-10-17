::ScreenManager.Screens[Screen.DIALOG_SCREEN] = class extends ::Screen{

    mTextContainer_ = null;
    mNextDialogButton_ = null;

    mContainerWindow_ = null;

    mDialogOptionsButtons_ = null;

    function receiveDialogSpokenEvent(id, data){
        setNewDialogText(data);
    }

    function receiveDialogOptionEvent(id, data){
        setNewDialogOptions(data);
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
        requestNextDialog();
    }

    function optionButtonPressed(widget, action){
        ::Base.mDialogManager.notifyOption(widget.getUserId());
        foreach(i in mDialogOptionsButtons_){
            i.setVisible(false);
        }

        mNextDialogButton_.setVisible(true);
    }

    function requestNextDialog(){
        ::Base.mDialogManager.notifyProgress();
    }

    function setup(data){
        mCustomPosition_ = true;
        mCustomSize_ = true;
        mDialogOptionsButtons_ = array(4);

        base.setup(data);

        ::InputManager.setActionSet(InputActionSets.DIALOG);

        _event.subscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.subscribe(Event.DIALOG_OPTION, receiveDialogOptionEvent, this);
        _event.subscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
    }

    function shutdown(){
        base.shutdown();

        ::InputManager.setActionSet(InputActionSets.EXPLORATION);

        _event.unsubscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.unsubscribe(Event.DIALOG_OPTION, receiveDialogOptionEvent, this);
        _event.unsubscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
    }

    function update(){
        if(_input.getButtonAction(::InputManager.dialogNext, _INPUT_PRESSED)){
            requestNextDialog();
        }
    }

    function recreate(){

        //Create a window to block inputs for when the popup appears.
        mWindow_ = _gui.createWindow("DialogScreen");
        //local winSize = Vec2(_window.getWidth(), _window.getHeight() * 0.3333);
        //mWindow_.setSize(winSize);
        //mWindow_.setPosition(0, _window.getHeight() * 0.6666);

        mWindow_.setVisualsEnabled(false);

        local winSize = ::drawable.copy();
        mWindow_.setSize(winSize);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        mContainerWindow_ = mWindow_.createWindow("DialogTextScreen");
        if(mobile){
            mContainerWindow_.setSize(winSize.x * 0.9, winSize.y * 0.3);
            mContainerWindow_.setPosition(winSize.x * 0.05, winSize.y * 0.65);
        }else{
            mContainerWindow_.setSize(winSize.x * 0.6, winSize.y * 0.3);
            mContainerWindow_.setPosition(winSize.x * 0.20, winSize.y * 0.65);
        }

        mTextContainer_ = mContainerWindow_.createLabel();
        mTextContainer_.setText(" ");

        mNextDialogButton_ = mContainerWindow_.createButton();
        mNextDialogButton_.setText("Next");
        mNextDialogButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);

        local buttonSize = mNextDialogButton_.getSize();
        //buttonSize *= 2;
        local winSize = mContainerWindow_.getSizeAfterClipping();
        mNextDialogButton_.setPosition(winSize.x - buttonSize.x, winSize.y - buttonSize.y);

        for(local i = 0; i < 4; i++){
            local button = mWindow_.createButton();
            button.setText(" ");
            button.setVisible(false);
            button.setUserId(i);
            button.attachListenerForEvent(optionButtonPressed, _GUI_ACTION_PRESSED, this);
            mDialogOptionsButtons_[i] = button;
        }

        setDialogVisible(false);
    }

    function setNewDialogText(textData){
        local targetText = null;
        local richText = null;
        if(typeof textData == "string"){
            targetText = textData;
        }else{
            //Rich text
            targetText = textData[0];
            richText = textData[1];
        }

        assert(targetText != null);
        mTextContainer_.setText(targetText, false);

        if(richText != null){
            mTextContainer_.setRichText(richText);
        }else{
            mTextContainer_.setTextColour(1, 1, 1, 1);
        }

        mTextContainer_.sizeToFit(mContainerWindow_.getSize().x * 0.95);
    }

    function setNewDialogOptions(options){
        local BUTTON_SIZE = 50;
        local containerPos = mContainerWindow_.getPosition();
        local containerSize = mContainerWindow_.getSize();
        for(local i = 0; i < 4; i++){
            local button = mDialogOptionsButtons_[i];
            if(i < options.len()){
                button.setText(options[i]);
                button.setVisible(true);
                local buttonWidth = button.getSize().x * 1.5;
                button.setSize(buttonWidth, BUTTON_SIZE);

                button.setPosition(containerPos.x + containerSize.x - buttonWidth, containerPos.y - BUTTON_SIZE * (options.len() - i));
            }else{
                button.setVisible(false);
            }
        }

        mNextDialogButton_.setVisible(false);
        _gui.reprocessMousePosition();
    }

    function setDialogVisible(visible){
        print("Setting dialog screen visible: " + visible.tostring());
        mWindow_.setHidden(!visible);
    }
}