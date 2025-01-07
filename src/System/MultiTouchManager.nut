::MultiTouchManager <- {

    mFingers_ = {}
    mTouches_ = []

    mPinchToZoomDistance_ = null
    mPrevPinchToZoomDistance_ = null

    function setup(){
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_BEGAN, recieveTouchBegan, this);
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_ENDED, recieveTouchEnded, this);
        _event.subscribe(_EVENT_SYSTEM_INPUT_TOUCH_MOTION, recieveTouchMotion, this);
    }

    function shutdown(){
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_BEGAN, recieveTouchBegan, this);
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_ENDED, recieveTouchEnded, this);
        _event.unsubscribe(_EVENT_SYSTEM_INPUT_TOUCH_MOTION, recieveTouchMotion, this);
    }

    function recieveTouchEnded(id, data){
        local f = data.tostring();
        mFingers_.rawdelete(f);

        local idx = mTouches_.find(f);
        if(idx != null){
            mTouches_[idx] = null;
        }
        checkForFinishedTouches_();
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
                print(pos);
            }catch(e){ }

            if(pos != null){
                mFingers_.rawset(f, pos);
            }
        }
    }

    function recieveTouchBegan(id, data){
        local f = data.fingerId.tostring();
        mFingers_.rawset(f, Vec2());
        mTouches_.append(f);
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