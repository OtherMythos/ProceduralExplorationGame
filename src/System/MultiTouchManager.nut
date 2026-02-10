::MultiTouchManager <- {

    mFingers_ = {}
    mTouches_ = []

    mPinchToZoomDistance_ = null
    mPrevPinchToZoomDistance_ = null

    //Registered MultiTouchButton instances.
    mButtons_ = []

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
        print("==multitouch== registerButton: total registered = " + (mButtons_.len() + 1));
        mButtons_.append(button);
    }

    /**
     * Unregister a MultiTouchButton so it no longer receives events.
     */
    function unregisterButton(button){
        local idx = mButtons_.find(button);
        print("==multitouch== unregisterButton: found = " + (idx != null) + ", total before = " + mButtons_.len());
        if(idx != null){
            mButtons_.remove(idx);
        }
    }

    function recieveTouchEnded(id, data){
        local f = data.tostring();
        print("==multitouch== TOUCH_ENDED finger=" + f + " registered_buttons=" + mButtons_.len());

        //Grab the last known position before removing.
        local lastPos = mFingers_.rawin(f) ? mFingers_[f] : null;
        mFingers_.rawdelete(f);

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
            print("==multitouch== unclaimed tap finger=" + f + " pos=" + lastPos.tostring());
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
                print("==multitouch== TOUCH_MOTION getTouchPosition error for finger " + f);
            }

            if(pos != null){
                mFingers_.rawset(f, pos);

                //Dispatch to registered buttons.
                //Use first-match-wins for late-begin: once a button claims
                //an unclaimed finger, stop dispatching to further buttons.
                local claimed = false;
                foreach(btn in mButtons_){
                    if(claimed && !btn.isFingerActive(f)) continue;
                    local accepted = btn.notifyTouchMoved_(f, pos);
                    if(accepted){
                        print("==multitouch== finger " + f + " claimed by button (first-match-wins)");
                        claimed = true;
                    }
                }
            }
        }else{
            print("==multitouch== TOUCH_MOTION finger not tracked: " + f);
        }
    }

    function recieveTouchBegan(id, data){
        local f = data.fingerId.tostring();
        print("==multitouch== TOUCH_BEGAN finger=" + f + " registered_buttons=" + mButtons_.len());

        //Try to get the initial position from the event data.
        local pos = Vec2();
        try{
            local touchPos = _input.getTouchPosition(data);
            if(touchPos != null) pos = touchPos;
        }catch(e){
            print("==multitouch== TOUCH_BEGAN getTouchPosition error for finger " + f);
        }

        print("==multitouch== TOUCH_BEGAN position=" + pos.tostring());
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