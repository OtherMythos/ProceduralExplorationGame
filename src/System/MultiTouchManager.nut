::MultiTouchManager <- {

    mFingers_ = {}
    mTouches_ = []

    mPinchToZoomDistance_ = null
    mPrevPinchToZoomDistance_ = null

    //Registered MultiTouchButton instances.
    mButtons_ = []

    //Desktop mouse-to-touch spoofing state.
    mMouseWasPressed_ = false

    //Raw native finger identifiers, keyed by string finger ID.
    //Used to re-query positions for fingers that started at (0,0).
    mRawFingerIds_ = {}

    function setup(){
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_BEGAN, recieveTouchBegan, this);
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_ENDED, recieveTouchEnded, this);
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_MOTION, recieveTouchMotion, this);
    }

    function shutdown(){
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_BEGAN, recieveTouchBegan, this);
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_ENDED, recieveTouchEnded, this);
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_MOTION, recieveTouchMotion, this);
        mButtons_.clear();
    }

    /**
     * Register a MultiTouchButton to receive dispatched touch events.
     * Returns a handle used for unregistering.
     */
    function registerButton(button){
        mButtons_.append(button);
    }

    /**
     * Unregister a MultiTouchButton so it no longer receives events.
     */
    function unregisterButton(button){
        local idx = mButtons_.find(button);
        if(idx != null){
            mButtons_.remove(idx);
        }
    }

    function recieveTouchEnded(id, data){
        local f = data.tostring();        //Grab the last known position before removing.
        local lastPos = mFingers_.rawin(f) ? mFingers_[f] : null;
        mFingers_.rawdelete(f);
        if(f in mRawFingerIds_) delete mRawFingerIds_[f];

        local idx = mTouches_.find(f);
        if(idx != null){
            mTouches_[idx] = null;
        }
        checkForFinishedTouches_();

        //Check whether any button had claimed this finger.
        local wasClaimed = false;
        foreach(btn in mButtons_){
            if(btn.isFingerActive(f)){
                wasClaimed = true;
                break;
            }
        }
        //Dispatch end to registered buttons.
        foreach(btn in mButtons_){
            btn.notifyTouchEnded_(f);
        }

        //If no button ever claimed this finger it was a quick tap
        //(no TOUCH_MOTION fired). Dispatch a tap notification so
        //buttons can detect double-tap gestures.
        if(!wasClaimed && lastPos != null){
            foreach(btn in mButtons_){
                btn.notifyTouchTapped_(f, lastPos);
            }
        }
    }

    function checkForFinishedTouches_(){
        local allNull = true;
        foreach(i in mTouches_){
            if(i != null){
                allNull = false;
                break;
            }
        }
        if(allNull){
            mTouches_.clear();
        }
    }

    function recieveTouchMotion(id, data){
        local f = data.tostring();
        if(mFingers_.rawin(f)){
            local pos = null;
            try{
                pos = _input.getTouchPosition(data);
            }catch(e){
            }

            if(pos != null){
                mFingers_.rawset(f, pos);

                //Dispatch to registered buttons.
                //Use first-match-wins for late-begin: once a button claims
                //an unclaimed finger, stop dispatching to further buttons.
                local claimed = false;
                foreach(idx, btn in mButtons_){
                    if(claimed && !btn.isFingerActive(f)) continue;
                    local accepted = btn.notifyTouchMoved_(f, pos);
                    if(accepted){
                        claimed = true;
                    }
                }
            }
        }else{

        }
    }

    function recieveTouchBegan(id, data){
        local f = data.fingerId.tostring();

        //Store the raw native finger identifier so we can re-query
        //its position later if the initial position is (0,0).
        mRawFingerIds_[f] <- data.fingerId;

        //Try to get the initial position from the event data.
        local pos = Vec2();
        try{
            local touchPos = _input.getTouchPosition(data.fingerId);
            if(touchPos != null) pos = touchPos;
        }catch(e){
        }

        mFingers_.rawset(f, pos);
        mTouches_.append(f);

        //Dispatch to registered buttons.
        foreach(btn in mButtons_){
            btn.notifyTouchBegan_(f, pos);
        }
    }

    function getTotalTouch(){
        return mTouches_.len();
    }
    function getTotalMultiTouch(){
        local num = 0;
        foreach(i in mTouches_){
            if(i != null) num++;
        }
        return num;
    }

    /**
     * Get the current position of a finger by its id string.
     * Returns Vec2 or null if the finger is not tracked.
     */
    function getFingerPosition(fingerId){
        local fid = fingerId.tostring();
        if(mFingers_.rawin(fid)) return mFingers_[fid];
        return null;
    }

    /**
     * Called each frame to resolve fingers that began at (0,0).
     * On iOS, TOUCH_BEGAN often lacks position data. If the finger
     * stays still, no TOUCH_MOTION fires either, leaving buttons
     * unable to claim it via late-begin. This function re-queries
     * the engine for the real position and dispatches a synthetic
     * motion event so buttons can perform their hit-test.
     */
    function pumpUnresolvedTouches(){
        foreach(fid, pos in mFingers_){
            if(pos.x != 0 || pos.y != 0) continue;
            if(!(fid in mRawFingerIds_)) continue;

            //Skip if any button already claimed this finger.
            local alreadyClaimed = false;
            foreach(btn in mButtons_){
                if(btn.isFingerActive(fid)){
                    alreadyClaimed = true;
                    break;
                }
            }
            if(alreadyClaimed) continue;

            //Try to get the real position from the engine.
            local realPos = null;
            try{
                realPos = _input.getTouchPosition(mRawFingerIds_[fid]);
            }catch(e){}
            if(realPos == null) continue;
            if(realPos.x == 0 && realPos.y == 0) continue;

            mFingers_[fid] = realPos;

            //Dispatch as motion so late-begin can claim the finger.
            local claimed = false;
            foreach(btn in mButtons_){
                if(claimed && !btn.isFingerActive(fid)) continue;
                local accepted = btn.notifyTouchMoved_(fid, realPos);
                if(accepted) claimed = true;
            }
        }
    }

    /**
     * Called each frame on desktop to synthesise touch events from
     * mouse input. Translates left-click press/drag/release into
     * the same touch began/motion/ended pipeline that real fingers
     * use, using "mouse" as the finger id.
     */
    function pumpMouseInput(){
        local mouseDown = _input.getMouseButton(_MB_LEFT);
        local fid = "mouse";

        if(mouseDown){
            //Normalise pixel-space mouse coords to 0-1 range.
            local rawX = _input.getMouseX().tofloat();
            local rawY = _input.getMouseY().tofloat();
            local px = rawX / ::canvasSize.x;
            local py = rawY / ::canvasSize.y;
            local pos = Vec2(px, py);

            if(!mMouseWasPressed_){
                //Synthesise touch-began.
                mFingers_.rawset(fid, pos);
                mTouches_.append(fid);
                foreach(btn in mButtons_){
                    btn.notifyTouchBegan_(fid, pos);
                }
            }else{
                //Synthesise touch-motion.
                mFingers_.rawset(fid, pos);
                local claimed = false;
                foreach(btn in mButtons_){
                    if(claimed && !btn.isFingerActive(fid)) continue;
                    local accepted = btn.notifyTouchMoved_(fid, pos);
                    if(accepted) claimed = true;
                }
            }
        }else{
            if(mMouseWasPressed_){
                //Synthesise touch-ended.

                local lastPos = mFingers_.rawin(fid) ? mFingers_[fid] : null;
                if(mFingers_.rawin(fid)) mFingers_.rawdelete(fid);
                local idx = mTouches_.find(fid);
                if(idx != null) mTouches_[idx] = null;
                checkForFinishedTouches_();

                local wasClaimed = false;
                foreach(btn in mButtons_){
                    if(btn.isFingerActive(fid)){
                        wasClaimed = true;
                        break;
                    }
                }
                foreach(btn in mButtons_){
                    btn.notifyTouchEnded_(fid);
                }
                if(!wasClaimed && lastPos != null){
                    foreach(btn in mButtons_){
                        btn.notifyTouchTapped_(fid, lastPos);
                    }
                }

                //Release cursor grab that processMouseDelta may have set.
                _window.grabCursor(false);
            }
        }

        mMouseWasPressed_ = mouseDown;
    }

    function determinePinchToZoom(){
        local d = false;
        if(getTotalTouch() == 2){
            if(getTotalMultiTouch() == 2){
                d = true;
                mPrevPinchToZoomDistance_ = mPinchToZoomDistance_;

                //The zoom has just started.
                local first = mFingers_[mTouches_[0]];
                local second = mFingers_[mTouches_[1]];
                mPinchToZoomDistance_ = first.distance(second);

                if(mPrevPinchToZoomDistance_ == null){
                    mPrevPinchToZoomDistance_ = mPinchToZoomDistance_;
                }

                local delta = mPrevPinchToZoomDistance_ - mPinchToZoomDistance_;
                if(delta >= 0.1) return null;
                if(delta <= -0.5) return null;
                return delta;
            }
        }
        if(!d){
            mPrevPinchToZoomDistance_ = null;
            mPinchToZoomDistance_ = null;
        }

        return null;
    }

};