::IconButton <- class{

    mButton_ = null;
    mIcon_ = null;

    constructor(window, iconDatablock, usePanelForButton=false){
        if(usePanelForButton){
            mButton_ = window.createPanel();
        }else{
            mButton_ = window.createButton();
        }
        mIcon_ = window.createPanel();
        mIcon_.setClickable(false);
        mIcon_.setDatablock(iconDatablock);
    }

    function setSize(size){
        mButton_.setSize(size);
        mIcon_.setSize(size);
    }

    function setPosition(position){
        mButton_.setPosition(position);
        mIcon_.setPosition(position);
    }

    function getPosition(){
        return mButton_.getPosition();
    }

    function getSize(){
        return mButton_.getSize();
    }

    function attachListenerForEvent(func, id, context){
        mButton_.attachListenerForEvent(func, id, context);
    }

    function setButtonVisualsEnabled(enabled){
        mButton_.setVisualsEnabled(enabled);
    }

    function setVisible(vis){
        mButton_.setVisible(vis);
        mIcon_.setVisible(vis);
    }

    function setButtonColour(colour){
        mButton_.setColour(colour);
    }

    function setColour(colour){
        mIcon_.setColour(colour);
    }

    function setNextWidget(widget, dir){
        mButton_.setNextWidget(widget, dir);
    }

    function setFocus(){
        mButton_.setFocus();
    }

    function getWidget(){
        return mButton_;
    }

    function setZOrder(zOrder){
        mButton_.setZOrder(zOrder);
        mIcon_.setZOrder(zOrder);
    }

    function setDisabled(disabled){
        mButton_.setDisabled(disabled);
    }

};

::IconButtonComplex <- class extends IconButton{

    mData_ = null;
    mLabel_ = null;

    constructor(window, data){
        mData_ = data;
        local usePanel = false;
        if(data.rawin("usePanelForButton")){
            usePanel = data.rawget("usePanelForButton");
        }
        base.constructor(window, data.icon, usePanel);

        if(data.rawin("label")){
            mLabel_ = window.createLabel();
            if(data.rawin("labelSizeModifier")){
                mLabel_.setDefaultFontSize(mLabel_.getDefaultFontSize() * data.rawget("labelSizeModifier"));
            }
            mLabel_.setText(data.label);
        }
    }

    function setSize(size){
        base.setSize(size);
        if(mData_.rawin("iconSize")){
            mIcon_.setSize(mData_.rawget("iconSize"));
        }
    }

    function getMinimumSize(){
        return (mLabel_.getPosition() + mLabel_.getSize()) - mButton_.getPosition();
    }

    function setText(text){
        if(mLabel_ != null){
            mLabel_.setText(text);
        }
    }

    function setVisible(visible){
        base.setVisible(visible);
        mLabel_.setVisible(visible);
    }

    function setPosition(pos){
        base.setPosition(pos);
        if(mData_.rawin("iconPosition")){
            mIcon_.setPosition(pos + mData_.rawget("iconPosition"));
        }
        if(mLabel_ != null){
            local labelPos = Vec2();
            if(mData_.rawin("labelPosition")){
                labelPos = mData_.rawget("labelPosition");
            }
            mLabel_.setPosition(pos + labelPos);
        }
    }

};

//Base class for IconButtonComplex animators
::IconButtonComplexAnimator <- class{
    function update(button, deltaTime){
        //Override this to implement animation logic
    }
};

//Wrapper class for animation data
::IconButtonComplexAnimator.WrappedAnimation <- class{
    animator = null;
    button = null;

    constructor(animator, button){
        this.animator = animator;
        this.button = button;
    }
};

//Test animator that moves the icon up and down with a sin wave
::IconButtonComplexSinWaveAnimator <- class extends ::IconButtonComplexAnimator{
    mTime_ = 0.0;
    mAmplitude_ = 0.0;
    mFrequency_ = 0.0;
    mOriginalIconPosition_ = null;

    constructor(amplitude=20.0, frequency=2.0){
        mAmplitude_ = amplitude;
        mFrequency_ = frequency;
    }

    function update(button, deltaTime){
        mTime_ += deltaTime;

        if(mOriginalIconPosition_ == null){
            mOriginalIconPosition_ = button.mIcon_.getPosition().copy();
        }

        local offset = sin(mTime_ * mFrequency_) * mAmplitude_;
        local newPos = mOriginalIconPosition_.copy();
        newPos.y += offset;
        button.mIcon_.setPosition(newPos);
    }
};

//Glittering particle effect animator
::IconButtonComplexGlitterAnimator <- class extends ::IconButtonComplexAnimator{
    mParticles_ = null;
    mParticleData_ = null;
    mNumParticles_ = 0;
    mParticleLifetime_ = 0.0;
    mSpawnRate_ = 0.0;
    mTimeSinceLastSpawn_ = 0.0;

    constructor(window, numParticles=8, particleLifetime=1.0, spawnRate=0.15){
        mNumParticles_ = numParticles;
        mParticleLifetime_ = particleLifetime;
        mSpawnRate_ = spawnRate;
        mParticles_ = [];
        mParticleData_ = [];

        //Create particle panels
        for(local i = 0; i < mNumParticles_; i++){
            local particle = window.createPanel();
            particle.setSize(Vec2(32, 32));
            particle.setVisible(false);
            particle.setClickable(false);
            particle.setDatablock("glimmerParticle");
            mParticles_.append(particle);
            //Initialize with random lifetime to stagger particles
            mParticleData_.append({
                "age": _random.rand() * mParticleLifetime_,
                "startX": 0.0,
                "startY": 0.0,
                "startRotation": 0.0,
                "endRotation": 0.0
            });
        }
    }

    function update(button, deltaTime){
        mTimeSinceLastSpawn_ += deltaTime;

        //Spawn new particles
        if(mTimeSinceLastSpawn_ >= mSpawnRate_){
            mTimeSinceLastSpawn_ -= mSpawnRate_;

            //Find an inactive particle to spawn
            for(local i = 0; i < mNumParticles_; i++){
                if(mParticleData_[i].age >= mParticleLifetime_){
                    //Spawn this particle at a random position on the button
                    local buttonPos = button.mButton_.getPosition();
                    local buttonSize = button.mButton_.getSize();

                    local randomX = _random.rand() * buttonSize.x;
                    local randomY = _random.rand() * buttonSize.y;

                    mParticles_[i].setCentre(buttonPos.x + randomX, buttonPos.y + randomY);
                    mParticles_[i].setVisible(true);

                    mParticleData_[i].age = 0.0;
                    mParticleData_[i].startX = buttonPos.x + randomX;
                    mParticleData_[i].startY = buttonPos.y + randomY;

                    //Set rotation: random start and end within a quarter turn (PI/2)
                    local maxRotationDeviation = PI / 2.0;
                    mParticleData_[i].startRotation = _random.rand() * (2.0 * PI);
                    mParticleData_[i].endRotation = mParticleData_[i].startRotation + (_random.rand() - 0.5) * maxRotationDeviation;
                    break;
                }
            }
        }

        //Update particles
        for(local i = 0; i < mNumParticles_; i++){
            local data = mParticleData_[i];
            if(data.age >= mParticleLifetime_) continue;

            data.age += deltaTime;

            //Calculate animation progress (0 to 1)
            local progress = data.age / mParticleLifetime_;

            //Fade in then out using easing
            local opacity = 0.0;
            if(progress < 0.5){
                //Fade in first half
                opacity = ::Easing.easeOutQuad(progress * 2.0);
            }else{
                //Fade out second half
                opacity = 1.0 - ::Easing.easeInQuad((progress - 0.5) * 2.0);
            }

            //Set opacity
            mParticles_[i].setColour(ColourValue(1.0, 1.0, 1.0, 0.8 * opacity));

            //Interpolate rotation between start and end
            local rotation = ::mix(data.startRotation, data.endRotation, progress);
            mParticles_[i].setOrientation(rotation);

            //Optional: slight movement
            if(data.age >= mParticleLifetime_){
                mParticles_[i].setVisible(false);
            }
        }
    }

    function shutdown(){
        foreach(particle in mParticles_){
            particle.destroyChild(particle);
        }
        mParticles_.clear();
        mParticleData_.clear();
    }
};

//Jump animator that makes the icon and label jump upward then rest
::IconButtonComplexJumpAnimator <- class extends ::IconButtonComplexAnimator{
    mTime_ = 0.0;
    mCycleDuration_ = 0.0;
    mJumpHeight_ = 0.0;
    mOriginalIconPosition_ = null;
    mOriginalLabelPosition_ = null;

    constructor(cycleDuration=0.9, jumpHeight=20.0){
        mCycleDuration_ = cycleDuration;
        mJumpHeight_ = jumpHeight;
    }

    function update(button, deltaTime){
        mTime_ += deltaTime;

        //Loop the animation
        if(mTime_ >= mCycleDuration_){
            mTime_ -= mCycleDuration_;
        }

        //Store original positions on first update
        if(mOriginalIconPosition_ == null){
            mOriginalIconPosition_ = button.mIcon_.getPosition().copy();
        }
        if(mOriginalLabelPosition_ == null && button.mLabel_ != null){
            mOriginalLabelPosition_ = button.mLabel_.getPosition().copy();
        }

        //Calculate animation phase (0 to 1)
        local phase = mTime_ / mCycleDuration_;

        //Animation breakdown:
        //0.0-0.333: Jumping phase (icon and label move up)
        //0.333-1.0: Resting phase (stationary)
        local offset = 0.0;
        if(phase < 0.333){
            //Jumping phase - use easeOutQuad for smooth upward motion
            local jumpProgress = phase / 0.333;
            //Move up then back down in the jump phase
            local jumpCurve = sin(jumpProgress * PI);
            offset = jumpCurve * mJumpHeight_;
        }

        //Apply offset to icon
        local newIconPos = mOriginalIconPosition_.copy();
        newIconPos.y -= offset;
        button.mIcon_.setPosition(newIconPos);

        //Apply offset to label if it exists
        if(button.mLabel_ != null && mOriginalLabelPosition_ != null){
            local newLabelPos = mOriginalLabelPosition_.copy();
            newLabelPos.y -= offset;
            button.mLabel_.setPosition(newLabelPos);
        }
    }
};

//Manager for IconButtonComplex animations
::IconButtonComplexAnimationManager <- class{
    mAnimations_ = null;

    constructor(){
        mAnimations_ = ::VersionPool();
    }

    function addAnimationToButton(animator, button){
        local wrappedAnimation = ::IconButtonComplexAnimator.WrappedAnimation(animator, button);
        return mAnimations_.store(wrappedAnimation);
    }

    function update(){
        for(local i = 0; i < mAnimations_.mObject_.len(); i++){
            local anim = mAnimations_.mObject_[i];
            if(anim != null){
                anim.animator.update(anim.button, 0.02);
            }
        }
    }

    function unstoreAnimation(animId){
        mAnimations_.unstore(animId);
    }

    function shutdown(){
        mAnimations_ = null;
    }
};