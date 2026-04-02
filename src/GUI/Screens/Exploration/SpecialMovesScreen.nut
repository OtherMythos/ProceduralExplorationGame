//Widget for a special move radial button, using a panel and label
::SpecialMoveButtonWidget <- class{
    //How much larger (pixels) the panel grows when selected
    static SELECTED_SIZE_BONUS = 14;
    //Lerp speed for the size animation each frame
    static ANIM_SPEED = 0.2;
    //Speed at which intro animation progresses per frame (0-1)
    static INTRO_SPEED = 0.1;
    //Scale multiplier at the very start of the intro
    static INTRO_SCALE_START = 0.6;

    mPanel_ = null;
    mLabel_ = null;
    mBaseSize_ = 0;
    mCurrentSize_ = 0.0;
    mTargetSize_ = 0.0;
    mBasePos_ = null;
    //Intro animation progress: 0 = start, 1 = complete
    mIntroT_ = 1.0;
    //Offset from final position to origin, lerped to zero during intro
    mIntroOffset_ = null;
    mDisabled_ = false;

    constructor(parent, text, size){
        mBaseSize_ = size;
        mCurrentSize_ = size.tofloat();
        mTargetSize_ = mCurrentSize_;
        mBasePos_ = Vec2(0, 0);
        mIntroOffset_ = Vec2(0, 0);

        mPanel_ = parent.createPanel();
        mPanel_.setSkinPack("Panel_midGrey");
        mPanel_.setSize(size, size);
        mPanel_.setClickable(false);

        mLabel_ = parent.createLabel();
        mLabel_.setText(text);
        mLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
        mLabel_.setClickable(false);
        //Fix the label to the base size so only the panel animates
        mLabel_.setSize(size, size);
    }

    function startIntro(origin){
        mIntroT_ = 0.0;
        //Offset so the button centre starts at origin and slides to its final position
        mIntroOffset_ = Vec2(origin.x - mBasePos_.x - mBaseSize_ * 0.5, origin.y - mBasePos_.y - mBaseSize_ * 0.5);
    }

    function setPosition(pos){
        mBasePos_ = Vec2(pos.x, pos.y);
        updatePositions_();
    }

    function setDisabled(disabled){
        mDisabled_ = disabled;
        if(disabled){
            mPanel_.setSkinPack("Panel_darkGrey");
            mPanel_.setColour(ColourValue(1, 1, 1, 0.75));
            mLabel_.setVisible(false);
        }
    }

    function setSelected(selected){
        if(mDisabled_) return;
        if(selected){
            mPanel_.setSkinPack("Panel_blue");
            mTargetSize_ = (mBaseSize_ + SELECTED_SIZE_BONUS).tofloat();
        }else{
            mPanel_.setSkinPack("Panel_midGrey");
            mTargetSize_ = mBaseSize_.tofloat();
        }
    }

    function update(){
        if(mIntroT_ < 1.0){
            mIntroT_ += INTRO_SPEED;
            if(mIntroT_ > 1.0){ mIntroT_ = 1.0; }
        }
        mCurrentSize_ += (mTargetSize_ - mCurrentSize_) * ANIM_SPEED;
        //easeOutBack gives a subtle overshoot pop on scale
        local easedScale = ::Easing.easeOutBack(mIntroT_);
        local introScale = INTRO_SCALE_START + (1.0 - INTRO_SCALE_START) * easedScale;
        local displaySize = mCurrentSize_ * introScale;
        mPanel_.setSize(displaySize, displaySize);
        //easeOutQuad for a fast initial fade that settles quickly
        if(!mDisabled_){
            local easedAlpha = ::Easing.easeOutQuad(mIntroT_);
            mPanel_.setColour(ColourValue(1, 1, 1, easedAlpha));
            mLabel_.setColour(ColourValue(1, 1, 1, easedAlpha));
        }
        updatePositions_();
    }

    function updatePositions_(){
        local easedScale = ::Easing.easeOutBack(mIntroT_);
        local introScale = INTRO_SCALE_START + (1.0 - INTRO_SCALE_START) * easedScale;
        local displaySize = mCurrentSize_ * introScale;
        //Grow/shrink the panel symmetrically around the base position
        local offset = (displaySize - mBaseSize_) * 0.5;
        //easeOutCubic for smooth deceleration as buttons slide to their positions
        local easedPos = ::Easing.easeOutCubic(mIntroT_);
        local ix = mIntroOffset_.x * (1.0 - easedPos);
        local iy = mIntroOffset_.y * (1.0 - easedPos);
        mPanel_.setPosition(Vec2(mBasePos_.x - offset + ix, mBasePos_.y - offset + iy));
        //Label slides with the panel during intro, then stays at base position
        mLabel_.setPosition(Vec2(mBasePos_.x + ix, mBasePos_.y + iy));
    }
};

::ScreenManager.Screens[Screen.SPECIAL_MOVES_SCREEN] = class extends ::Screen{

    //Radius of the radial button ring from the ring centre (pixels)
    static RING_RADIUS = 110;
    //Base size of each square button (pixels)
    static BUTTON_SIZE = 90;
    //Number of special move buttons in the ring
    static NUM_BUTTONS = 4;
    //Minimum finger distance from ring centre to activate segment selection
    static SELECTION_DEADZONE = 40;

    mButtons_ = null;
    mRingCentre_ = null;
    mSelectedIndex_ = -1;
    //The finger id from MultiTouchManager that triggered this screen
    mFingerId_ = null;
    mFingerWasActive_ = false;

    function setup(data){
        if(data != null && data.rawin("centre")){
            mRingCentre_ = data.rawget("centre");
        }
        if(data != null && data.rawin("fingerId")){
            mFingerId_ = data.rawget("fingerId");
        }
        recreate();
    }

    function recreate(){
        mWindow_ = _gui.createWindow("SpecialMovesScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mSelectedIndex_ = -1;
        createButtons_();
        positionButtons_();
        //Animate buttons in from the ring centre
        local origin = Vec2(
            mRingCentre_ != null ? mRingCentre_.x : _window.getWidth() / 2.0,
            mRingCentre_ != null ? mRingCentre_.y : _window.getHeight() / 2.0
        );
        for(local i = 0; i < NUM_BUTTONS; i++){
            mButtons_[i].startIntro(origin);
        }
        //Check if the finger is currently tracked
        mFingerWasActive_ = (mFingerId_ != null && ::MultiTouchManager.getFingerPosition(mFingerId_) != null);
    }

    function createButtons_(){
        mButtons_ = array(NUM_BUTTONS);
        local moves = ::Base.mPlayerStats.getSpecialMoves();
        for(local i = 0; i < NUM_BUTTONS; i++){
            local moveId = (i < moves.len()) ? moves[i] : SpecialMoveId.NONE;
            local moveDef = ::SpecialMoves[moveId];
            local label = (moveDef != null) ? moveDef.getName() : "None";
            mButtons_[i] = ::SpecialMoveButtonWidget(mWindow_, label, BUTTON_SIZE);
            if(moveId == SpecialMoveId.NONE){
                mButtons_[i].setDisabled(true);
            }
        }
    }

    function positionButtons_(){
        local centreX = mRingCentre_ != null ? mRingCentre_.x : _window.getWidth() / 2.0;
        local centreY = mRingCentre_ != null ? mRingCentre_.y : _window.getHeight() / 2.0;

        //Arrange buttons in a radial ring, starting from the top and going clockwise
        local startAngle = -PI / 2.0;
        local angleStep = (PI * 2.0) / NUM_BUTTONS;

        for(local i = 0; i < NUM_BUTTONS; i++){
            local angle = startAngle + angleStep * i;
            local bx = centreX + cos(angle) * RING_RADIUS - BUTTON_SIZE / 2.0;
            local by = centreY + sin(angle) * RING_RADIUS - BUTTON_SIZE / 2.0;
            mButtons_[i].setPosition(Vec2(bx, by));
        }
    }

    function getFingerPixelPos_(){
        if(mFingerId_ == null) return null;
        local pos = ::MultiTouchManager.getFingerPosition(mFingerId_);
        if(pos == null) return null;
        //Touch positions from MultiTouchManager are normalised 0-1; convert to pixel space
        return Vec2(pos.x * ::canvasSize.x, pos.y * ::canvasSize.y);
    }

    function update(){
        local fingerPos = getFingerPixelPos_();
        local fingerActive = (fingerPos != null);

        local centreX = mRingCentre_ != null ? mRingCentre_.x : _window.getWidth() / 2.0;
        local centreY = mRingCentre_ != null ? mRingCentre_.y : _window.getHeight() / 2.0;

        //Determine selection from finger position
        local newSelectedIndex = -1;
        if(fingerActive){
            local dx = fingerPos.x - centreX;
            local dy = fingerPos.y - centreY;
            local dist = sqrt(dx * dx + dy * dy);

            //Only select past the deadzone radius
            if(dist >= SELECTION_DEADZONE){
                local angle = atan2(dy, dx);
                local startAngle = -PI / 2.0;
                local angleStep = (PI * 2.0) / NUM_BUTTONS;
                local halfStep = angleStep * 0.5;

                for(local i = 0; i < NUM_BUTTONS; i++){
                    local segCentre = startAngle + angleStep * i;
                    local diff = angle - segCentre;
                    //Normalise diff to [-PI, PI]
                    while(diff > PI) diff -= PI * 2.0;
                    while(diff < -PI) diff += PI * 2.0;
                    if(diff >= -halfStep && diff < halfStep){
                        if(!mButtons_[i].mDisabled_){
                            newSelectedIndex = i;
                        }
                        break;
                    }
                }
            }
        }

        //Capture selection before updating so the release check sees the last active index
        local indexBeforeUpdate = mSelectedIndex_;

        //Update button selection state only when it changes
        if(newSelectedIndex != mSelectedIndex_){
            if(mSelectedIndex_ >= 0){
                mButtons_[mSelectedIndex_].setSelected(false);
            }
            mSelectedIndex_ = newSelectedIndex;
            if(mSelectedIndex_ >= 0){
                mButtons_[mSelectedIndex_].setSelected(true);
            }
        }

        //Animate all buttons each frame
        for(local i = 0; i < NUM_BUTTONS; i++){
            mButtons_[i].update();
        }

        //On finger release, trigger the selected move (if any) and close
        if(mFingerWasActive_ && !fingerActive){
            mSelectedIndex_ = indexBeforeUpdate;
            if(mSelectedIndex_ >= 0){
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                if(world != null){
                    world.triggerPlayerSpecialMove(mSelectedIndex_);
                }
            }
            closeScreen();
        }
        mFingerWasActive_ = fingerActive;
    }

    function shutdown(){
        //Release the SPECIAL_MOVES world state for this finger
        if(mFingerId_ != null){
            local world = ::Base.mExplorationLogic.mCurrentWorld_;
            if(world != null){
                world.releaseStateForFinger(mFingerId_);
            }
        }
        base.shutdown();
    }
};
