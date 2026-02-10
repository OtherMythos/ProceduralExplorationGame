::PlayerDirectJoystick <- class{

    mButton_ = null;
    mBackgroundPanel_ = null;
    mHandle_ = null;

    mCurrentJoystickDir_ = null;
    mJoystickOrigin_ = null;
    mJoystickPositionTarget_ = null;

    MAX_OPACITY_COUNT = 60;
    mCurrentOpacityCount_ = 0;

    mUseCooldown_ = 0.0;
    mCooldownAnim_ = 0.0;

    constructor(parent){
        mCurrentJoystickDir_ = ::Vec2_ZERO;

        mButton_ = parent.createButton();
        mButton_.setVisualsEnabled(false);
        mButton_.attachListenerForEvent(function(widget, action){
            //On mobile, MultiTouchButton handles directing input per-finger.
            //The legacy "mouse" path must not fire here or it will race and
            //never be released (the per-frame mouse release is desktop-only).
            if(::Base.getTargetInterface() == TargetInterface.MOBILE) return;
            local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
            if(currentWorld != null){
                currentWorld.requestDirectingPlayer();
            }
        }, _GUI_ACTION_PRESSED, this);

        mBackgroundPanel_ = parent.createPanel();
        mBackgroundPanel_.setDatablock("guiExplorationJoystickArrows");
        mBackgroundPanel_.setColour(ColourValue(1, 1, 1, 0.2));
        mBackgroundPanel_.setClickable(false);

        mHandle_ = parent.createPanel();
        mHandle_.setDatablock("guiExplorationJoystickHandle");
        mHandle_.setColour(ColourValue(1, 1, 1, 0.2));
        mHandle_.setClickable(false);

        mBackgroundPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
        mHandle_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);

        _event.subscribe(Event.PLAYER_DIRECTING_CHANGED, receivePlayerDirectingChanged, this);
    }

    function shutdown(){
        _event.unsubscribe(Event.PLAYER_DIRECTING_CHANGED, receivePlayerDirectingChanged, this);
    }

    function setVisible(visible){
        mButton_.setVisible(visible);
        mBackgroundPanel_.setVisible(visible);
        mHandle_.setVisible(visible);
    }

    function setSize(size){
        mButton_.setSize(size);
        mBackgroundPanel_.setSize(size);
        mHandle_.setSize(size * 0.5);
    }

    function setPosition(pos){
        mButton_.setPosition(pos);
        mBackgroundPanel_.setPosition(pos);
        mJoystickOrigin_ = mButton_.getCentre();
        mHandle_.setCentre(mJoystickOrigin_);
    }

    function setJoystickDirection(dir){
        mCurrentJoystickDir_ = dir.normalisedCopy();
        setJoystickDirection_(mCurrentJoystickDir_);
    }

    function receivePlayerDirectingChanged(id, data){
        setJoystickDirection(data);
        mUseCooldown_ = 1.0;
        setColours_(ColourValue(1, 1, 1, 1));
    }

    function setJoystickDirection_(dir){
        mHandle_.setCentre(mJoystickOrigin_ + (dir * 20));
    }

    function setColours_(colourVal){
        mBackgroundPanel_.setColour(colourVal);
        mHandle_.setColour(colourVal);
    }

    function update(){
        //mAnim += 0.01;
        //setJoystickDirection(Vec2(sin(mAnim), cos(mAnim)));

        if(mUseCooldown_ >= 0){
            mUseCooldown_-=0.02;

            if(mUseCooldown_ <= 0.0){
                //mJoystickPositionTarget_ = mJoystickOrigin_;
                mCooldownAnim_ = 1.0;
            }
        }

        if(mUseCooldown_ <= 0){
            local startAnim = mCooldownAnim_;
            mCooldownAnim_ = ::accelerationClampCoordinate_(mCooldownAnim_, 0.2, 0.1);
            if(startAnim != mCooldownAnim_){
                //Something actually changed
                setColours_(ColourValue(1, 1, 1, mCooldownAnim_));
                local posAnim = ::calculateSimpleAnimationInRange(mCurrentJoystickDir_, ::Vec2_ZERO, mCooldownAnim_, 1.0, 0.2);
                setJoystickDirection_(posAnim);
            }
        }
    }

};