/**
 * MultiTouchInputContext
 *
 * Replaces the single-state MousePressContext with a system that tracks
 * which finger owns which input state. Multiple states can coexist
 * (e.g. camera rotation on one finger + zoom on another) but the
 * compatibility matrix prevents nonsensical combinations.
 *
 * Blocking states like POPUP_WINDOW cancel all active fingers.
 * Each state can only be held by one finger at a time.
 */
::MultiTouchInputContext <- class{

    //Map of fingerId (string) -> WorldMousePressContexts state
    mFingerStates_ = null;
    //Reverse map of WorldMousePressContexts state -> fingerId (string)
    mStateFingers_ = null;
    mGui_ = null;

    mDoubleClickTimer_ = 0;
    mDoubleClick_ = false;

    //Blocking state active means no other states can be entered.
    mBlockingStateActive_ = false;

    /**
     * Compatibility matrix.
     * If a pair of states is listed here they CAN coexist on separate fingers.
     * Pairs not listed are mutually exclusive.
     * Populated in constructor because the enum is not available at class-definition time.
     */
    mCompatiblePairs_ = null;

    /**
     * States that block all other input when active.
     * Entering one of these cancels every other active finger.
     */
    mBlockingStates_ = null;

    constructor(){
        mFingerStates_ = {};
        mStateFingers_ = {};

        mCompatiblePairs_ = [
            //Camera rotation and zoom can happen at the same time on different fingers.
            [WorldMousePressContexts.ORIENTING_CAMERA, WorldMousePressContexts.ZOOMING],
            [WorldMousePressContexts.ORIENTING_CAMERA_WITH_MOVEMENT, WorldMousePressContexts.ZOOMING],
            //Camera rotation and swiping attack on different fingers.
            [WorldMousePressContexts.ORIENTING_CAMERA, WorldMousePressContexts.SWIPING_ATTACK],
            [WorldMousePressContexts.ORIENTING_CAMERA_WITH_MOVEMENT, WorldMousePressContexts.SWIPING_ATTACK],
            //Camera rotation and player directing on different fingers.
            [WorldMousePressContexts.ORIENTING_CAMERA, WorldMousePressContexts.DIRECTING_PLAYER],
            [WorldMousePressContexts.ORIENTING_CAMERA_WITH_MOVEMENT, WorldMousePressContexts.DIRECTING_PLAYER],
            //Zoom and swiping attack.
            [WorldMousePressContexts.ZOOMING, WorldMousePressContexts.SWIPING_ATTACK],
            //Directing player and swiping attack.
            [WorldMousePressContexts.DIRECTING_PLAYER, WorldMousePressContexts.SWIPING_ATTACK],
            //Directing player and zoom.
            [WorldMousePressContexts.DIRECTING_PLAYER, WorldMousePressContexts.ZOOMING],
        ];

        mBlockingStates_ = [
            WorldMousePressContexts.POPUP_WINDOW,
        ];
    }

    function update(){
        if(mDoubleClickTimer_ > 0) mDoubleClickTimer_--;
    }

    /**
     * Attempt to begin a state for the given finger.
     * Returns true if the state was granted, false if denied.
     */
    function requestStateForFinger(fingerId, state){
        local fid = fingerId.tostring();
        print("==multitouch== Context.requestStateForFinger finger=" + fid + " state=" + state + " activeStates=" + mStateFingers_.len());

        //If a blocking state is active deny everything.
        if(mBlockingStateActive_ && !isBlockingState_(state)){
            print("==multitouch== Context.requestStateForFinger DENIED: blocking state active");
            return false;
        }

        //If this finger already owns a state, deny (release first).
        if(fid in mFingerStates_){
            print("==multitouch== Context.requestStateForFinger DENIED: finger already owns state " + mFingerStates_[fid]);
            return false;
        }

        //If this state is already owned by another finger, deny.
        if(state in mStateFingers_){
            print("==multitouch== Context.requestStateForFinger DENIED: state already owned by finger " + mStateFingers_[state]);
            return false;
        }

        //Check if this is a blocking state.
        if(isBlockingState_(state)){
            //Cancel every existing finger state.
            cancelAllFingers_();
            mBlockingStateActive_ = true;
            assignState_(fid, state);
            if(mGui_) mGui_.notifyBlockInput(true);
            return true;
        }

        //Check compatibility with every currently active state.
        foreach(activeState, _ in mStateFingers_){
            if(!arePairCompatible_(state, activeState)){
                print("==multitouch== Context.requestStateForFinger DENIED: incompatible with active state " + activeState);
                return false;
            }
        }

        assignState_(fid, state);
        print("==multitouch== Context.requestStateForFinger ACCEPTED");
        return true;
    }

    /**
     * Release the state held by a specific finger.
     */
    function releaseStateForFinger(fingerId){
        local fid = fingerId.tostring();
        if(!(fid in mFingerStates_)) return;

        local state = mFingerStates_[fid];
        delete mFingerStates_[fid];
        if(state in mStateFingers_){
            delete mStateFingers_[state];
        }

        if(isBlockingState_(state)){
            mBlockingStateActive_ = false;
            if(mGui_) mGui_.notifyBlockInput(false);
        }
    }

    /**
     * Get the state owned by a specific finger, or null.
     */
    function getStateForFinger(fingerId){
        local fid = fingerId.tostring();
        if(fid in mFingerStates_) return mFingerStates_[fid];
        return null;
    }

    /**
     * Get the finger that owns a specific state, or null.
     */
    function getFingerForState(state){
        if(state in mStateFingers_) return mStateFingers_[state];
        return null;
    }

    /**
     * Check whether a given state is currently active on any finger.
     */
    function isStateActive(state){
        return (state in mStateFingers_);
    }

    /**
     * Get an array of all currently active states.
     */
    function getActiveStates(){
        local states = [];
        foreach(state, _ in mStateFingers_){
            states.append(state);
        }
        return states;
    }

    /**
     * Returns true if no finger owns any state.
     */
    function isEmpty(){
        return mFingerStates_.len() == 0;
    }

    /**
     * Legacy compatibility: release all fingers.
     * Equivalent to old notifyMouseEnded().
     */
    function notifyAllEnded(){
        cancelAllFingers_();
        mBlockingStateActive_ = false;
        if(mGui_) mGui_.notifyBlockInput(false);
    }

    /**
     * Legacy compatibility: behaves like the old single-state getCurrentState.
     * Returns the first active state or null. Prefer isStateActive() instead.
     */
    function getCurrentState(){
        foreach(state, _ in mStateFingers_){
            return state;
        }
        return null;
    }

    /**
     * Legacy compatibility for the old notifyMouseEnded.
     * Releases all fingers.
     */
    function notifyMouseEnded(){
        notifyAllEnded();
    }

    /**
     * Legacy compatibility: request without finger (uses "mouse" as finger id).
     * Used during transition period for code that hasn't been updated yet.
     */
    function requestTargetEnemy(){
        return requestStateForFinger("mouse", WorldMousePressContexts.TARGET_ENEMY);
    }
    function requestFlagLogic(){
        return requestStateForFinger("mouse", WorldMousePressContexts.PLACING_FLAG);
    }
    function requestOrientingCameraWithMovement(){
        local result = requestStateForFinger("mouse", WorldMousePressContexts.ORIENTING_CAMERA_WITH_MOVEMENT);
        if(result){
            if(mDoubleClickTimer_ > 0){
                mDoubleClick_ = true;
            }
            mDoubleClickTimer_ = 20;
        }
        return result;
    }
    function requestOrientingCamera(){
        return requestStateForFinger("mouse", WorldMousePressContexts.ORIENTING_CAMERA);
    }
    function requestZoomingCamera(){
        return requestStateForFinger("mouse", WorldMousePressContexts.ZOOMING);
    }
    function requestDirectingPlayer(){
        return requestStateForFinger("mouse", WorldMousePressContexts.DIRECTING_PLAYER);
    }
    function requestPopupWindow(){
        return requestStateForFinger("mouse", WorldMousePressContexts.POPUP_WINDOW);
    }
    function requestSwipingAttack(){
        return requestStateForFinger("mouse", WorldMousePressContexts.SWIPING_ATTACK);
    }
    function checkDoubleClick(){
        local retVal = mDoubleClick_;
        mDoubleClick_ = false;
        return retVal;
    }

    function setGuiObject(guiObj){
        mGui_ = guiObj;
    }

    //
    //Internal helpers
    //

    function assignState_(fid, state){
        mFingerStates_[fid] <- state;
        mStateFingers_[state] <- fid;
    }

    function cancelAllFingers_(){
        mFingerStates_ = {};
        mStateFingers_ = {};
    }

    function isBlockingState_(state){
        foreach(s in mBlockingStates_){
            if(s == state) return true;
        }
        return false;
    }

    function arePairCompatible_(stateA, stateB){
        if(stateA == stateB) return false;
        foreach(pair in mCompatiblePairs_){
            if((pair[0] == stateA && pair[1] == stateB) ||
               (pair[0] == stateB && pair[1] == stateA)){
                return true;
            }
        }
        return false;
    }
};
