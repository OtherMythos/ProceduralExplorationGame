/**
 * MultiTouchButton
 *
 * A touch-region that detects presses inside a rectangular area.
 * Unlike a GUI button, this supports multiple simultaneous fingers:
 * each finger that lands inside the region gets its own callback
 * and can be tracked independently.
 *
 * Touch events are dispatched by MultiTouchManager (the single
 * subscriber to engine touch events). Buttons register themselves
 * with MultiTouchManager on construction and unregister on shutdown.
 *
 * Usage:
 *   local btn = MultiTouchButton(pos, size);
 *   btn.setOnPressed(function(fingerId, pos){ ... });
 *   btn.setOnReleased(function(fingerId){ ... });
 */
::MultiTouchButton <- class{

    mPosition_ = null;
    mSize_ = null;
    mVisible_ = true;

    //Callbacks: function(fingerId, touchPos)
    mOnPressed_ = null;
    //Callback: function(fingerId)
    mOnReleased_ = null;
    //Callback: function(fingerId, touchPos)
    mOnMoved_ = null;
    //Callback: function(fingerId, touchPos) – quick tap (no motion)
    mOnTapped_ = null;

    //Set of fingerIds currently inside this button region.
    mActiveTouches_ = null;

    constructor(pos, size){
        mPosition_ = pos;
        mSize_ = size;
        mActiveTouches_ = {};

        ::MultiTouchManager.registerButton(this);
    }

    function shutdown(){
        ::MultiTouchManager.unregisterButton(this);
        //Release any remaining active touches.
        local toRelease = [];
        foreach(fid, _ in mActiveTouches_){
            toRelease.append(fid);
        }
        foreach(fid in toRelease){
            releaseTouch_(fid);
        }
        mActiveTouches_ = {};
    }

    function setOnPressed(callback){
        mOnPressed_ = callback;
    }
    function setOnReleased(callback){
        mOnReleased_ = callback;
    }
    function setOnMoved(callback){
        mOnMoved_ = callback;
    }
    function setOnTapped(callback){
        mOnTapped_ = callback;
    }

    function setPosition(pos){
        mPosition_ = pos;
    }
    function getPosition(){
        return mPosition_;
    }

    function setSize(size){
        mSize_ = size;
    }
    function getSize(){
        return mSize_;
    }

    function getCentre(){
        return mPosition_ + mSize_ * 0.5;
    }

    function setVisible(visible){
        mVisible_ = visible;
        if(!mVisible_){
            //Release all active touches when hidden.
            local toRelease = [];
            foreach(fid, _ in mActiveTouches_){
                toRelease.append(fid);
            }
            foreach(fid in toRelease){
                releaseTouch_(fid);
            }
        }
    }

    function isVisible(){
        return mVisible_;
    }

    /**
     * Check whether a given finger is currently pressed inside this button.
     */
    function isFingerActive(fingerId){
        return (fingerId.tostring() in mActiveTouches_);
    }

    /**
     * Get the total number of fingers currently pressing this button.
     */
    function getActiveTouchCount(){
        return mActiveTouches_.len();
    }

    /**
     * Get all active finger ids as an array.
     */
    function getActiveFingerIds(){
        local ids = [];
        foreach(fid, _ in mActiveTouches_){
            ids.append(fid);
        }
        return ids;
    }

    //
    //Called by MultiTouchManager — do not call directly.
    //

    function notifyTouchBegan_(fid, pos){
        print("==multitouch== Button.notifyTouchBegan_ finger=" + fid + " pos=" + pos.tostring() + " visible=" + mVisible_);
        if(!mVisible_){
            print("==multitouch== Button.notifyTouchBegan_ rejected: not visible");
            return;
        }
        local hit = hitTest_(pos);
        print("==multitouch== Button.notifyTouchBegan_ hitTest result=" + hit);
        if(!hit) return;

        mActiveTouches_[fid] <- pos;
        print("==multitouch== Button.notifyTouchBegan_ accepted, calling onPressed");
        if(mOnPressed_ != null){
            local accepted = mOnPressed_(fid, pos);
            //If the callback explicitly returns false, reject the finger.
            if(accepted == false){
                print("==multitouch== Button.notifyTouchBegan_ rejected by callback");
                delete mActiveTouches_[fid];
                return;
            }
        }
    }

    function notifyTouchEnded_(fid){
        print("==multitouch== Button.notifyTouchEnded_ finger=" + fid + " was_active=" + (fid in mActiveTouches_));
        releaseTouch_(fid);
    }

    function notifyTouchMoved_(fid, pos){
        //If this finger isn't tracked yet, treat motion as a late-begin.
        //Touch position is often unavailable at TOUCH_BEGAN so the first
        //TOUCH_MOTION with a real position is when we can actually hit-test.
        if(!(fid in mActiveTouches_)){
            if(!mVisible_) return false;
            if(!hitTest_(pos)) return false;

            print("==multitouch== Button.notifyTouchMoved_ late-begin finger=" + fid + " pos=" + pos.tostring());
            mActiveTouches_[fid] <- pos;
            if(mOnPressed_ != null){
                local accepted = mOnPressed_(fid, pos);
                if(accepted == false){
                    print("==multitouch== Button.notifyTouchMoved_ late-begin rejected by callback");
                    delete mActiveTouches_[fid];
                    return false;
                }
            }
            return true;
        }

        mActiveTouches_[fid] = pos;
        if(mOnMoved_ != null){
            mOnMoved_(fid, pos);
        }
        //Return true so the dispatcher knows this finger is owned by this
        //button and stops dispatching to lower-priority buttons.
        return true;
    }

    //
    //Internal helpers
    //

    function releaseTouch_(fid){
        if(!(fid in mActiveTouches_)) return;
        delete mActiveTouches_[fid];
        if(mOnReleased_ != null){
            mOnReleased_(fid);
        }
    }

    /**
     * Called by MultiTouchManager when a finger ends without ever
     * being claimed by any button (quick tap, no TOUCH_MOTION).
     * If the tap falls inside this button's region, fire onTapped.
     *
     * When the position is (0,0) it means the engine never provided
     * a valid touch position (common for quick taps on mobile).
     * In that case skip the hit-test — only buttons with an onTapped
     * callback will actually respond, and the tap was not claimed by
     * any higher-priority button either.
     */
    function notifyTouchTapped_(fid, pos){
        if(!mVisible_) return;
        if(mOnTapped_ == null) return;
        local positionUnknown = (pos.x == 0 && pos.y == 0);
        if(!positionUnknown && !hitTest_(pos)) return;
        print("==multitouch== Button.notifyTouchTapped_ finger=" + fid + " pos=" + pos.tostring() + " blind=" + positionUnknown);
        mOnTapped_(fid, pos);
    }

    function hitTest_(pos){
        //Touch positions are normalised (0-1), but button bounds are in
        //canvas pixel coordinates. Scale touch pos to canvas space.
        local px = pos.x * ::canvasSize.x;
        local py = pos.y * ::canvasSize.y;
        local hit = (px >= mPosition_.x &&
                py >= mPosition_.y &&
                px < mPosition_.x + mSize_.x &&
                py < mPosition_.y + mSize_.y);
        print("==multitouch== Button.hitTest_ pos=" + pos.tostring() + " scaled=(" + px + "," + py + ") bounds=[" + mPosition_.tostring() + "," + (mPosition_ + mSize_).tostring() + "] result=" + hit);
        return hit;
    }
};
