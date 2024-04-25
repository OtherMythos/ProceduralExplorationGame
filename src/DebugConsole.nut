::DebugConsole <- {
    mParentWindow_ = null
    mCommandBox_ = null
    mOutputLabel_ = null

    mCommands_ = null
    mOutput_ = null

    mActive_ = false
    COMMAND_POINTER = "> "

    DebugCommandEntry = class{
        mName = null;
        mDescription = null;
        mNumParams = null;
        mTypeMask = null;
        mCallback = null;
        constructor(name, description, numParams, typeMask, callback){
            mName = name;
            mDescription = description;
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

        mCommandBox_.setText(COMMAND_POINTER);
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

        pushOutput(format("'%s' %s", GAME_TITLE, ::getVersionInfo().info));
        pushOutput("Type 'help' for more information.");

        mParentWindow_.setVisible(false);
    }

    function editboxCallback(widget, action){
        if(!mActive_) return;
        local value = widget.getText();
        if(value.len() <= COMMAND_POINTER.len()){
            widget.setText(COMMAND_POINTER);
        }
        local pressed = (value.find("\n") != null);
        if(pressed){
            //Remove the \n
            local stripped = value.slice(0, value.len()-1);

            //Ensure we can find the pointer at the start of the command.
            assert(stripped.find(COMMAND_POINTER) == 0);
            stripped = stripped.slice(COMMAND_POINTER.len());

            actuateCommand(stripped);
            widget.setText(COMMAND_POINTER);
        }
    }

    function actuateCommand(command){
        local splitVals = split(command, " ");
        print(_prettyPrint(command));
        pushOutput(format("%s%s", COMMAND_POINTER, command));
        if(splitVals.len() <= 0){
            return;
        }

        local id = splitVals[0];
        foreach(i in mCommands_){
            if(i.mName == id){
                splitVals.remove(0);
                local output = i.actuateCommand(splitVals);
                pushOutput(output);
                return;
            }
        }
        pushOutput(format("No command '%s'", id));
    }

    function pushOutput(output){
        mOutput_.append(output);
        if(mOutput_.len() >= 50){
            mOutput_.remove(0);
        }
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

    function registerCommand(name, desc, numParams, typeMask, callback){
        mCommands_.append(DebugCommandEntry(name, desc, numParams, typeMask, callback));
    }
}
::DebugConsole.setup();

::DebugConsole.registerCommand("help", "Print help message", 0, "", function(command){
    local output = "";
    foreach(c,i in ::DebugConsole.mCommands_){
        output += (format("%s - %s", i.mName, i.mDescription));
        if(c != ::DebugConsole.mCommands_.len()-1) output += "\n";
    }
    return output;
});