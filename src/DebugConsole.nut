::DebugConsole <- {
    mParentWindow_ = null
    mCommandBox_ = null
    mOutputLabel_ = null

    mCommands_ = null
    mOutput_ = null

    mActive_ = false

    DebugCommandEntry = class{
        mName = null;
        mNumParams = null;
        mTypeMask = null;
        mCallback = null;
        constructor(name, numParams, typeMask, callback){
            mName = name;
            mNumParams = numParams;
            mTypeMask = typeMask;
            mCallback = callback;
        }
        function actuateCommand(command){
            return mCallback(command);
        }
    }

    function toggleActive(){
        setActive(!mActive_);
    }

    function setActive(active){
        mActive_ = active;
        mParentWindow_.setVisible(active);

        mCommandBox_.setText("");
        if(active){
            mCommandBox_.setFocus();
        }

        ::InputManager.setActionSet(active ? InputActionSets.DEBUG_CONSOLE : InputActionSets.EXPLORATION);
    }

    function update(){
        if(_input.getButtonAction(::InputManager.debugConsoleCloseConsole, _INPUT_PRESSED)){
            toggleActive();
        }
    }

    function setup(){
        mCommands_ = [];
        mOutput_ = [];

        mParentWindow_ = _gui.createWindow();
        mParentWindow_.setPosition(0, 0);
        mParentWindow_.setSize(1920, 1080);
        mParentWindow_.setZOrder(200);

        local actual = mParentWindow_.getSizeAfterClipping();
        mCommandBox_ = mParentWindow_.createEditbox();
        mCommandBox_.setSize(actual.x, 100);
        mCommandBox_.setPosition(0, actual.y - 100);

        mOutputLabel_ = mParentWindow_.createLabel();
        positionOutputLabel();

        mCommandBox_.attachListenerForEvent(editboxCallback, _GUI_ACTION_VALUE_CHANGED, this);

        mParentWindow_.setVisible(false);
    }

    function editboxCallback(widget, action){
        local value = widget.getText();
        local pressed = (value.find("\n") != null);
        if(pressed){
            //Remove the \n
            local stripped = value.slice(0, value.len()-1);
            local splitVals = split(stripped, " ");
            if(splitVals.len() >= 1){
                actuateCommand(splitVals);
            }
            widget.setText("");
        }
    }

    function actuateCommand(command){
        print(_prettyPrint(command));
        local id = command[0];
        foreach(i in mCommands_){
            if(i.mName == id){
                command.remove(0);
                local output = i.actuateCommand(command);
                pushOutput(output);
                return;
            }
        }
        pushOutput(format("No command '%s'", id));
    }

    function pushOutput(output){
        mOutput_.append(output);
        local string = "";
        for(local i = 0; i < mOutput_.len(); i++){
            string += mOutput_[i];
            string += "\n";
        }
        mOutputLabel_.setText(string);
        positionOutputLabel();
    }

    function positionOutputLabel(){
        local actual = mParentWindow_.getSizeAfterClipping();
        mOutputLabel_.setPosition(0, actual.y - 100 - mOutputLabel_.getSize().y);
    }

    function registerCommand(name, numParams, typeMask, callback){
        mCommands_.append(DebugCommandEntry(name, numParams, typeMask, callback));
    }
}
::DebugConsole.setup();