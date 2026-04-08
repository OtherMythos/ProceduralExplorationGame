//Direction the incoming screen slides in from.
enum TransitionDirection{
    UP,
    DOWN,
    LEFT,
    RIGHT
};

::ScreenManager.Transitions[ScreenTransition.BACKGROUND_FADE_SLIDE] = class extends ::Transition{

    mSkipBackgroundAnim_ = false;
    mFrames_ = 0;
    mDuration_ = 12;
    mTargetAlpha_ = 0.8;
    mStartPos_ = null;
    mTargetPos_ = null;

    constructor(transitionData){
        base.constructor(transitionData);
    }

    function setup(incomingScreen, outgoingScreen, data){
        base.setup(incomingScreen, outgoingScreen, data);
        mSkipBackgroundAnim_ = (mIncomingScreen_.mBackgroundWindow_ == null);

        local direction = TransitionDirection.DOWN;
        local slideOffset = 50;

        if(data != null){
            if(data.rawin("alpha")) mTargetAlpha_ = data.alpha;
            if(data.rawin("duration")) mDuration_ = data.duration;
            if(data.rawin("direction")) direction = data.direction;
            if(data.rawin("slideOffset")) slideOffset = data.slideOffset;
        }

        if(!mSkipBackgroundAnim_){
            mIncomingScreen_.mBackgroundWindow_.setColour(ColourValue(1, 1, 1, 0));
        }

        if(mIncomingScreen_.mWindow_ != null){
            mTargetPos_ = mIncomingScreen_.mWindow_.getPosition().copy();
            mStartPos_ = mTargetPos_.copy();
            switch(direction){
                case TransitionDirection.UP:    mStartPos_.y -= slideOffset; break;
                case TransitionDirection.DOWN:  mStartPos_.y += slideOffset; break;
                case TransitionDirection.LEFT:  mStartPos_.x -= slideOffset; break;
                case TransitionDirection.RIGHT: mStartPos_.x += slideOffset; break;
            }
            mIncomingScreen_.mWindow_.setPosition(mStartPos_);
            mIncomingScreen_.positionCloseButton_();
        }
    }

    function update(){
        if(mFrames_ >= mDuration_) return;

        mFrames_++;
        local progress = mFrames_.tofloat() / mDuration_.tofloat();
        local eased = ::Easing.easeOutCubic(progress);

        if(!mSkipBackgroundAnim_){
            mIncomingScreen_.mBackgroundWindow_.setColour(ColourValue(1, 1, 1, mTargetAlpha_ * eased));
        }

        if(mTargetPos_ != null){
            local currentPos = Vec2(
                mStartPos_.x + (mTargetPos_.x - mStartPos_.x) * eased,
                mStartPos_.y + (mTargetPos_.y - mStartPos_.y) * eased
            );
            mIncomingScreen_.mWindow_.setPosition(currentPos);
            mIncomingScreen_.positionCloseButton_();
        }
    }

    function isComplete(){
        return mFrames_ >= mDuration_;
    }

    function shutdown(){
        //Snap to final state in case shutdown is called before animation completes.
        if(mIncomingScreen_ != null){
            if(!mSkipBackgroundAnim_){
                mIncomingScreen_.mBackgroundWindow_.setColour(ColourValue(1, 1, 1, mTargetAlpha_));
            }
            if(mTargetPos_ != null && mIncomingScreen_.mWindow_ != null){
                mIncomingScreen_.mWindow_.setPosition(mTargetPos_);
                mIncomingScreen_.positionCloseButton_();
            }
        }
        base.shutdown();
    }
};


