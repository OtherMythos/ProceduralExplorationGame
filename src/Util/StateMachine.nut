::Util <- {};

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

    function tickCount(){
        mCurrentCount_++;
    }
};