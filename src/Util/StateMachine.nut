::Util <- {};

::Util.SimpleStateMachine <- class{
    mStates_ = null;
    mCurrentState_ = null;
    mData_ = null;
    mStateInstance_ = null;

    constructor(data=null){
        mData_ = data;
    }

    function setState(state){
        assert(state < mStates_.len());
        if(state == mCurrentState_) return false;

        if(mStateInstance_ != null){
            mStateInstance_.end(this);
        }

        if(state == 0){
            resetState();
            return false;
        }

        local entry = mStates_[state];
        assert(entry != null);
        mStateInstance_ = entry();
        mCurrentState_ = state;
        if(entry != null){
            mStateInstance_.start(this);
        }

        return true;
    }

    function notify(event){
        if(mStateInstance_ == null) return false;

        local newState = mStateInstance_.notify(this, event);
        if(newState != null && newState != mCurrentState_){
            if(!setState(newState)) return false;
        }

        return true;
    }

    function resetState(){
        mCurrentState_ = null;
        mStateInstance_ = null;
    }

    function update(){
        if(mStateInstance_ == null) return false;
        local newState = mStateInstance_.update(this);

        if(newState != null && newState != mCurrentState_){
            if(!setState(newState)) return false;
        }

        return true;
    }

};

::Util.SimpleState <- class{
    function start(data) {}
    function end(data) {}
    function update(data) {}
};

::Util.StateMachine <- class{

    mStates_ = null;
    mCurrentState_ = null;
    mData_ = null;
    mStateInstance_ = null;
    mCurrentStateCount_ = 0;

    constructor(data){
        mData_ = data;
    }

    function setState(state){
        assert(state < mStates_.len());

        if(state == 0){
            resetState();
            return false;
        }

        local entry = mStates_[state];
        assert(entry != null);
        mStateInstance_ = entry();
        if(entry != null){
            mStateInstance_.start(mData_);
        }
        mCurrentState_ = state;
        mCurrentStateCount_ = 0;

        return true;
    }

    function resetState(){
        mCurrentState_ = null;
        mStateInstance_ = null;
        mCurrentStateCount_ = 0;
    }

    function update(){
        if(mCurrentState_ == null) return false;
        local greater = mCurrentStateCount_ >= mStateInstance_.mTotalCount_;
        local anim = greater ? 1.0 : mCurrentStateCount_.tofloat() / mStateInstance_.mTotalCount_.tofloat();
        local newState = mStateInstance_.update(anim, mData_);

        if(newState != null && newState != mCurrentState_){
            if(!setState(newState)) return false;
        }

        if(greater){
            //Attempt to end the state.
            if(mStateInstance_.mNextState_ != null){
                if(!setState(mStateInstance_.mNextState_)) return false;
            }
        }else{
            mCurrentStateCount_++;
        }

        return true;
    }
};

::Util.State <- class{
    mTotalCount_ = 0;
    mNextState_ = null;

    function start(data) {}
    function update(p, data) {}
};