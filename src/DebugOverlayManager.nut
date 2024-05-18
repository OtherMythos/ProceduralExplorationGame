::DebugOverlayManager <- {

    mActiveOverlays_ = []
    mSetupState_ = false

    DebugOverlay = class{
        mId_ = null;
        mWindow_ = null;
        mLabel_ = null;
        mText_ = null;
        mDirty_ = false;
        constructor(id){
            mId_ = id;
            mText_ = "";

            mWindow_ = _gui.createWindow("DebugOverlay" + id);
            mWindow_.setZOrder(199);

            mLabel_ = mWindow_.createLabel();
            mLabel_.setText("test");
        }

        function setPosition(){

        }

        function appendText(text){
            mText_ += (text + "\n");
            mDirty_ = true;
        }

        function update(){
            if(mDirty_){
                mLabel_.setText(mText_);
                mDirty_ = false;
                mWindow_.setSize(mWindow_.calculateChildrenSize());
                mText_ = "";
            }
        }
    }

    function setupOverlay(idx){
        if(idx+1 >= mActiveOverlays_.len()){
            mActiveOverlays_.resize(idx+1);
        }
        mActiveOverlays_[idx] = DebugOverlay(idx);

        if(mActiveOverlays_.len() > 0 && !mSetupState_){
            //Setup the scripted state so update is called.
            _scriptingState.startState("DebugOverlay", "script://DebugOverlayScriptedState.nut");
            mSetupState_ = true;
        }
    }

    /**
     * Append text to the overlay and mark it as dirty.
     * If the overlay of id does not exist the function does nothing.
     */
    function appendText(id, text){
        if(id >= mActiveOverlays_.len()) return;
        local overlay = mActiveOverlays_[id];
        if(overlay == null) return;
        overlay.appendText(text);
    }

    function update(){
        foreach(i in mActiveOverlays_){
            if(i == null) continue;
            i.update();
        }
    }
};