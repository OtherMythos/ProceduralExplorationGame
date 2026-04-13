
local DIALOG_OPTION_ANIM_FRAMES = 16;
local DIALOG_OPTION_ANIM_STAGGER = 4;
local DIALOG_OPTION_ANIM_OFFSET_Y = 16;

local DialogOptionButton = class{
    mButton_ = null;
    mLabel_ = null;
    mSize_ = null;
    mRestPos_ = null;
    static PADDING_X = 20;
    static PADDING_Y = 2;

    function setup(parentWindow){
        mButton_ = parentWindow.createButton();
        mLabel_ = parentWindow.createLabel();
        mSize_ = null;
        mRestPos_ = null;

        mButton_.setOpacity(0.95);
        mButton_.setVisualsEnabled(true);
        mLabel_.setClickable(false);
    }

    function setText(text){
        mLabel_.setText(text);
        mSize_ = null;
    }

    function setVisible(visible){
        mButton_.setVisible(visible);
        mLabel_.setVisible(visible);
    }

    function setUserId(id){
        mButton_.setUserId(id);
    }

    function attachListenerForEvent(callback, eventType, environment){
        mButton_.attachListenerForEvent(callback, eventType, environment);
    }

    function setPosition(x, y){
        mRestPos_ = Vec2(x, y);
        mButton_.setPosition(x, y);
        mLabel_.setPosition(x + PADDING_X, y + PADDING_Y);
    }

    //p: 0.0 = start of intro (offset above, transparent), 1.0 = fully shown at rest
    function applyAnimProgress(p){
        local py = mRestPos_.y - DIALOG_OPTION_ANIM_OFFSET_Y * (1.0 - p);
        mButton_.setPosition(mRestPos_.x, py);
        mLabel_.setPosition(mRestPos_.x + PADDING_X, py + PADDING_Y);
        mButton_.setOpacity(0.95 * p);
        mLabel_.setTextColour(1, 1, 1, p);
    }

    function setZOrder(zorder){
        mButton_.setZOrder(zorder);
        mLabel_.setZOrder(zorder + 1);
    }

    function sizeToFit(maxWidth){
        mLabel_.sizeToFit(maxWidth);
        local labelSize = mLabel_.getSize();
        mButton_.setSize(labelSize.x + PADDING_X * 2, labelSize.y + PADDING_Y * 2);
        mSize_ = mButton_.getSize();
    }

    function getSize(){
        if(mSize_ == null){
            mSize_ = mButton_.getSize();
        }
        return mSize_;
    }

    function setTextHorizontalAlignment(alignment){
        mLabel_.setTextHorizontalAlignment(alignment);
    }

    function setTextColour(r, g, b, a){
        mLabel_.setTextColour(r, g, b, a);
    }
}

local DialogActorTitle = class {
    mWindow_ = null;
    mBackgroundPanel_ = null;
    mLabel_ = null;

    static PADDING_X = 12;
    static PADDING_Y = 6;

    function setup(parentWindow){
        mWindow_ = parentWindow.createWindow("DialogActorTitle");
        mWindow_.setVisualsEnabled(false);
        mWindow_.setClipBorders(0, 0, 0, 0);

        mBackgroundPanel_ = mWindow_.createPanel();
        mBackgroundPanel_.setSkinPack("Button_midGrey");
        mBackgroundPanel_.setClickable(false);

        mLabel_ = mWindow_.createLabel();
        mLabel_.setClickable(false);
    }

    function setActorName(name){
        mLabel_.setText(name);
        mLabel_.sizeToFit(400);
        local labelSize = mLabel_.getSize();
        local totalWidth = labelSize.x + PADDING_X * 2;
        if(totalWidth < 100) totalWidth = 100;
        local totalHeight = labelSize.y + PADDING_Y * 2;
        mWindow_.setSize(totalWidth, totalHeight);
        mBackgroundPanel_.setSize(totalWidth, totalHeight);
        local labelSize = mLabel_.getSize();
        local centeredX = (totalWidth - labelSize.x) / 2.0;
        mLabel_.setPosition(centeredX, PADDING_Y);
    }

    function setPosition(x, y){
        mWindow_.setPosition(x, y);
    }

    function setVisible(visible){
        mWindow_.setVisible(visible);
    }

    function setAlpha(alpha){
        mBackgroundPanel_.setOpacity(alpha * 0.95);
        mLabel_.setTextColour(1, 1, 1, alpha);
    }

    function setZOrder(zorder){
        mWindow_.setZOrder(zorder);
        mBackgroundPanel_.setZOrder(zorder + 1);
        mLabel_.setZOrder(zorder + 2);
    }

    function getSize(){
        return mWindow_.getSize();
    }
}

::ScreenManager.Screens[Screen.DIALOG_SCREEN] = class extends ::Screen{

    mTextContainer_ = null;
    mNextDialogButton_ = null;

    mContainerWindow_ = null;
    mFullScreenInputWindow_ = null;
    mFullScreenInputButton_ = null;

    mDialogOptionsButtons_ = null;
    mDialogOptionsAnimFrame_ = 0;
    mDialogOptionsAnimating_ = false;
    mActionSetId_ = null;

    mTextJumpFrame_ = 0;
    mTextJumping_ = false;
    static TEXT_JUMP_FRAMES = 10;
    static TEXT_JUMP_HEIGHT = 5.0;

    mCurrentDialogText_ = null;
    mCurrentDialogRichText_ = null;
    mCurrentDialogColour_ = null;
    mAnimationProgress_ = 0.0;
    mTotalGlyphs_ = 0;
    mGlyphsPerFrame_ = 1.0;
    mAnimating_ = false;

    mLottieAnimationPanel_ = null;
    mLottieAnimationPanelBackground_ = null;
    mLottieAnimation_ = null;
    mLottieAnimationSecond_ = null;
    mLottieDatablock_ = null;
    mLottieBackgroundDatablock_ = null;
    mShowLottieAnimation_ = false;
    mMobileInterface_ = false;
    mActorTitle_ = null;
    mCurrentActorName_ = null;
    mDialogIntroAnimating_ = false;
    mDialogIntroFrame_ = 0;
    mDialogIntroTargetPos_ = null;
    mDialogIntroOffset_ = null;
    mActorTitleTargetPos_ = null;
    mActorTitleIntroOffset_ = null;

    static DIALOG_INTRO_FRAMES = 24;

    function receiveDialogSpokenEvent(id, data){
        setNewDialogText(data);
    }

    function receiveDialogOptionEvent(id, data){
        setNewDialogOptions(data);
    }

    function receiveDialogMetaEvent(id, data){
        if("ended" in data && data.ended){
            mCurrentActorName_ = null;
            ::ScreenManager.backupScreen(mLayerIdx);
            //setDialogVisible(false);
            return;
        }

        if("started" in data && data.started){
            setDialogVisible(true);
        }

        if("actorSet" in data){
            mCurrentActorName_ = data.actorSet;
            local name = getNameForActorId(mCurrentActorName_);
            mActorTitle_.setActorName(name);
            mTextContainer_.setDefaultFont(getFontForActorId_(mCurrentActorName_));
            local visible = actorIdMakesTitleVisible(mCurrentActorName_)
            positionActorTitle_();
            mActorTitle_.setVisible(visible);
            if(visible){
                if(mDialogIntroAnimating_){
                    local p = min(1.0, mDialogIntroFrame_.tofloat() / DIALOG_INTRO_FRAMES.tofloat());
                    applyDialogIntroAnimation_(p);
                }else{
                    mActorTitle_.setAlpha(1.0);
                }
            }
        }
    }

    function actorIdMakesTitleVisible(actorId){
        return (actorId < 100);
    }

    function getFontForActorId_(actorId){
        if(actorId == 100) return 6;
        return 0;
    }

    function getNameForActorId(actorId){
        local name = ::Base.mDialogManager.getActorName(actorId);
        if(name != null) return name;
        return " ";
    }

    function nextButtonPressed(widget, action){
        requestNextDialog();
    }

    function optionButtonPressed(widget, action){
        ::Base.mDialogManager.notifyOption(widget.getUserId());
        foreach(i in mDialogOptionsButtons_){
            i.setVisible(false);
        }

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        if(!mobile){
            mNextDialogButton_.setVisible(true);
        }
    }

    function requestNextDialog(){
        ::Base.mDialogManager.notifyProgress();
    }

    function setup(data){
        mCustomPosition_ = true;
        mCustomSize_ = true;
        mDialogOptionsButtons_ = array(4);

        base.setup(data);

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.DIALOG);

        _event.subscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.subscribe(Event.DIALOG_OPTION, receiveDialogOptionEvent, this);
        _event.subscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);
    }

    function shutdown(){
        base.shutdown();

        ::InputManager.popActionSet(mActionSetId_);

        _event.unsubscribe(Event.DIALOG_SPOKEN, receiveDialogSpokenEvent, this);
        _event.unsubscribe(Event.DIALOG_OPTION, receiveDialogOptionEvent, this);
        _event.unsubscribe(Event.DIALOG_META, receiveDialogMetaEvent, this);

        //Cleanup Lottie animations
        if(mLottieAnimation_ != null){
            ::Base.mLottieManager.destroyForId(mLottieAnimation_);
        }
        if(mLottieAnimationSecond_ != null){
            ::Base.mLottieManager.destroyForId(mLottieAnimationSecond_);
        }

        if(mFullScreenInputWindow_ != null){
            _gui.destroy(mFullScreenInputWindow_);
        }
    }

    function setZOrder(idx){
        base.setZOrder(idx);
        if(mFullScreenInputWindow_ != null){
            mFullScreenInputWindow_.setZOrder(idx + 1);
        }
    }

    function update(){
        updateDialogIntroAnimation_();
        updateTextJumpAnimation_();

        // Animate dialog option buttons from top to bottom
        if(mDialogOptionsAnimating_){
            mDialogOptionsAnimFrame_++;
            local staggerIdx = 0;
            local visibleCount = 0;
            //Count visible buttons and animate in reverse (highest index = topmost visually)
            for(local i = 0; i < mDialogOptionsButtons_.len(); i++){
                if(mDialogOptionsButtons_[i].mButton_ != null && mDialogOptionsButtons_[i].mButton_.getVisible()){
                    visibleCount++;
                }
            }
            for(local i = mDialogOptionsButtons_.len() - 1; i >= 0; i--){
                local btn = mDialogOptionsButtons_[i];
                if(btn.mButton_ == null || !btn.mButton_.getVisible()) continue;
                local p = ::clampValue((mDialogOptionsAnimFrame_ - staggerIdx * DIALOG_OPTION_ANIM_STAGGER).tofloat() / DIALOG_OPTION_ANIM_FRAMES.tofloat(), 0.0, 1.0);
                btn.applyAnimProgress(::Easing.easeOutQuad(p));
                staggerIdx++;
            }
            if(mDialogOptionsAnimFrame_ >= DIALOG_OPTION_ANIM_FRAMES + (visibleCount - 1) * DIALOG_OPTION_ANIM_STAGGER){
                mDialogOptionsAnimating_ = false;
            }
        }

        mTotalGlyphs_ = mTextContainer_.getNumGlyphs();
        if(mAnimating_){
            mAnimationProgress_ += mGlyphsPerFrame_;
            if(mAnimationProgress_ >= mTotalGlyphs_){
                mAnimationProgress_ = mTotalGlyphs_.tofloat();
                mAnimating_ = false;
                //Text animation complete, show Lottie animation if on mobile
                checkShowAnimation_();
            }
            updateTextAnimation_();
        }

        if(_input.getButtonAction(::InputManager.dialogNext, _INPUT_PRESSED)){
            if(mAnimating_){
                //Finish animation immediately
                mAnimationProgress_ = mTotalGlyphs_.tofloat();
                mAnimating_ = false;
                updateTextAnimation_();
                checkShowAnimation_();
            }else{
                requestNextDialog();
            }
        }
    }

    function updateTextJumpAnimation_(){
        if(!mTextJumping_) return;

        mTextJumpFrame_++;
        local p = mTextJumpFrame_.tofloat() / TEXT_JUMP_FRAMES.tofloat();
        if(p >= 1.0){
            mTextJumping_ = false;
            mContainerWindow_.setPosition(mDialogIntroTargetPos_.x, mDialogIntroTargetPos_.y);
            return;
        }
        //Arc up with a sine curve
        local offset = sin(p * PI) * TEXT_JUMP_HEIGHT;
        mContainerWindow_.setPosition(mDialogIntroTargetPos_.x, mDialogIntroTargetPos_.y - offset);
    }

    function startTextJumpAnimation_(){
        if(mDialogIntroTargetPos_ == null) return;
        mTextJumpFrame_ = 0;
        mTextJumping_ = true;
    }

    function checkShowAnimation_(){
        if(!mMobileInterface_) return;

        mShowLottieAnimation_ = true;
        mLottieAnimationPanel_.setVisible(true);
        mLottieAnimationPanelBackground_.setVisible(true);
    }

    function startDialogIntroAnimation_(){
        mDialogIntroFrame_ = 0;
        mDialogIntroAnimating_ = true;
        applyDialogIntroAnimation_(0.0);
    }

    function updateDialogIntroAnimation_(){
        if(!mDialogIntroAnimating_) return;

        mDialogIntroFrame_++;
        local p = min(1.0, mDialogIntroFrame_.tofloat() / DIALOG_INTRO_FRAMES.tofloat());
        applyDialogIntroAnimation_(p);
        if(p >= 1.0){
            mDialogIntroAnimating_ = false;
        }
    }

    function applyDialogIntroAnimation_(progress){
        if(mContainerWindow_ == null || mDialogIntroTargetPos_ == null || mDialogIntroOffset_ == null) return;

        local easedPos = ::Easing.easeOutCubic(progress);
        local easedAlpha = ::Easing.easeOutQuad(progress);
        local offsetScale = 1.0 - easedPos;
        local introPos = mDialogIntroTargetPos_ + Vec2(mDialogIntroOffset_.x * offsetScale, mDialogIntroOffset_.y * offsetScale);
        local containerAlpha = 0.95 * easedAlpha;

        mContainerWindow_.setPosition(introPos.x, introPos.y);
        mContainerWindow_.setOpacity(containerAlpha);

        if(mNextDialogButton_ != null){
            mNextDialogButton_.setOpacity(easedAlpha);
            mNextDialogButton_.setTextColour(1, 1, 1, easedAlpha);
        }

        if(mActorTitle_ != null && mCurrentActorName_ != null && mActorTitleTargetPos_ != null && mActorTitleIntroOffset_ != null && actorIdMakesTitleVisible(mCurrentActorName_)){
            local titlePos = mActorTitleTargetPos_ + Vec2(mActorTitleIntroOffset_.x * offsetScale, mActorTitleIntroOffset_.y * offsetScale);
            mActorTitle_.setPosition(titlePos.x, titlePos.y);
            mActorTitle_.setAlpha(easedAlpha);
        }
    }

    function recreate(){

        //Create a window to block inputs for when the popup appears.
        mWindow_ = _gui.createWindow("DialogScreen");
        //local winSize = Vec2(_window.getWidth(), _window.getHeight() * 0.3333);
        //mWindow_.setSize(winSize);
        //mWindow_.setPosition(0, _window.getHeight() * 0.6666);

        mWindow_.setVisualsEnabled(false);

        local winSize = ::drawable.copy();
        mWindow_.setSize(winSize);

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        mMobileInterface_ = mobile;

        mContainerWindow_ = mWindow_.createWindow("DialogTextScreen");
        if(mobile){
            mContainerWindow_.setSize(winSize.x * 0.9, winSize.y * 0.3);
            mContainerWindow_.setPosition(winSize.x * 0.05, winSize.y * 0.65);
        }else{
            mContainerWindow_.setSize(winSize.x * 0.6, winSize.y * 0.3);
            mContainerWindow_.setPosition(winSize.x * 0.20, winSize.y * 0.65);
        }

        mContainerWindow_.setSkinPack("Button_midGrey");
        mContainerWindow_.setOpacity(0.95);

    mDialogIntroTargetPos_ = mContainerWindow_.getPosition();
    mDialogIntroOffset_ = Vec2(0, mobile ? 28 : 20);
    mActorTitleTargetPos_ = null;
    mActorTitleIntroOffset_ = Vec2(0, mobile ? 18 : 14);

        mContainerWindow_.setClickable(!mobile);

        mTextContainer_ = mContainerWindow_.createAnimatedLabel();
        mTextContainer_.setText(" ");
        mTextContainer_.setShadowOutline(true, ::Colour_BLACK, Vec2(2, 2));

        mNextDialogButton_ = mContainerWindow_.createButton();
        mNextDialogButton_.setText("Next");
        mNextDialogButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);
        mNextDialogButton_.setVisible(!mobile);

        local buttonSize = mNextDialogButton_.getSize();
        //buttonSize *= 2;
        local winSize = mContainerWindow_.getSizeAfterClipping();
        mNextDialogButton_.setPosition(winSize.x - buttonSize.x, winSize.y - buttonSize.y);

        //Setup Lottie animations
        local animSize = Vec2(64, 64);
        mLottieAnimationPanelBackground_ = mContainerWindow_.createPanel();
        mLottieAnimationPanelBackground_.setSize(animSize);
        mLottieAnimationPanel_ = mContainerWindow_.createPanel();
        mLottieAnimationPanel_.setSize(animSize);

        mLottieAnimationPanel_.setClickable(false);
        mLottieAnimationPanelBackground_.setClickable(false);

        animSize *= ::resolutionMult;

        local lottieMan = ::Base.mLottieManager;
        local blendBlock = _hlms.getBlendblock({
            "blend_operation": _HLMS_SBO_MAX,
        });
        mLottieAnimation_ = lottieMan.createAnimation(LottieAnimationType.SPRITE_SHEET, "res://build/assets/lottie/mobileTouch.json", animSize.x.tointeger(), animSize.y.tointeger(), true, blendBlock);

        local blendBlock = _hlms.getBlendblock({
            "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_COLOUR,
            "blend_operation": _HLMS_SBF_DEST_COLOUR,
        });
        mLottieAnimationSecond_ = lottieMan.createAnimation(LottieAnimationType.SPRITE_SHEET, "res://build/assets/lottie/mobileTouch.json", animSize.x.tointeger(), animSize.y.tointeger(), true, blendBlock);

        local datablock = lottieMan.getDatablockForAnim(mLottieAnimation_);
        mLottieAnimationPanel_.setDatablock(datablock);
        mLottieDatablock_ = datablock;
        datablock = lottieMan.getDatablockForAnim(mLottieAnimationSecond_);
        mLottieAnimationPanelBackground_.setDatablock(datablock);
        mLottieBackgroundDatablock_ = datablock;

        mLottieAnimationPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
        mLottieAnimationPanelBackground_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
        mShowLottieAnimation_ = false;
        mLottieAnimationPanel_.setVisible(false);
        mLottieAnimationPanelBackground_.setVisible(false);

        //Setup full-screen input window for mobile
        if(mobile){
            mFullScreenInputWindow_ = _gui.createWindow("DialogFullScreenInput");
            mFullScreenInputWindow_.setSize(_window.getWidth(), _window.getHeight());
            mFullScreenInputWindow_.setPosition(0, 0);
            mFullScreenInputWindow_.setClipBorders(0, 0, 0, 0);
            mFullScreenInputWindow_.setVisualsEnabled(false);

            mFullScreenInputButton_ = mFullScreenInputWindow_.createButton();
            mFullScreenInputButton_.setSize(_window.getWidth(), _window.getHeight());
            mFullScreenInputButton_.setPosition(0, 0);
            mFullScreenInputButton_.setVisualsEnabled(false);
            mFullScreenInputButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);
        }

        local buttonTargetWindows = mWindow_;
        if(mobile){
            buttonTargetWindows = mFullScreenInputWindow_;
        }

        for(local i = 0; i < 4; i++){
            local optionButton = DialogOptionButton();
            optionButton.setup(mFullScreenInputWindow_);
            optionButton.setUserId(i);
            optionButton.attachListenerForEvent(optionButtonPressed, _GUI_ACTION_PRESSED, this);
            mDialogOptionsButtons_[i] = optionButton;
        }

        //Setup actor title widget
        mActorTitle_ = DialogActorTitle();
        mActorTitle_.setup(mWindow_);
        mActorTitle_.setVisible(false);
        if(mCurrentActorName_ != null){
            mActorTitle_.setActorName(mCurrentActorName_);
            positionActorTitle_();
            mActorTitle_.setVisible(true);
        }

        setDialogVisible(false);
    }

    function setNewDialogText(textData){
        local targetText = null;
        local richText = null;
        if(typeof textData == "string"){
            targetText = textData;
        }else{
            //Rich text
            targetText = textData[0];
            richText = textData[1];
        }

        assert(targetText != null);
        mCurrentDialogText_ = targetText;
        mCurrentDialogRichText_ = richText;
        if(mCurrentActorName_ != null){
            mTextContainer_.setDefaultFont(getFontForActorId_(mCurrentActorName_));
        }
        mTextContainer_.setText(targetText, false);

        if(richText != null){
            mTextContainer_.setRichText(richText);
            mCurrentDialogColour_ = ColourValue(1, 1, 1, 1);
        }else{
            mCurrentDialogColour_ = ColourValue(1, 1, 1, 1);
            mTextContainer_.setTextColour(1, 1, 1, 1);
        }

        mTextContainer_.sizeToFit(mContainerWindow_.getSizeAfterClipping().x * 0.95);
        mTotalGlyphs_ = mTextContainer_.getNumGlyphs();
        mAnimationProgress_ = 0.0;
        mAnimating_ = true;

        //Initialize all glyphs with 0 opacity
        initialiseGlyphOpacity_();

        //Hide Lottie animation when new text arrives
        if(mMobileInterface_){
            mShowLottieAnimation_ = false;
            mLottieAnimationPanel_.setVisible(false);
            mLottieAnimationPanelBackground_.setVisible(false);
        }

        //Position Lottie animation in the container
        positionLottieAnimation_();

        startTextJumpAnimation_();
    }

    function positionActorTitle_(){
        local containerPos = mDialogIntroTargetPos_;
        if(containerPos == null){
            containerPos = mContainerWindow_.getPosition();
        }
        local containerSize = mContainerWindow_.getSize();
        local titleSize = mActorTitle_.getSize();
        local overlapAmount = 8;
        local xPos = containerPos.x + containerSize.x - titleSize.x - 20;
        local yPos = containerPos.y - titleSize.y + overlapAmount;
        mActorTitleTargetPos_ = Vec2(xPos, yPos);
        mActorTitle_.setPosition(xPos, yPos);
    }

    function positionLottieAnimation_(){
        if(!mMobileInterface_) return;
        //Position at the same location as the Next button
        local buttonSize = mNextDialogButton_.getSize();
        local containerSize = mContainerWindow_.getSizeAfterClipping();
        local animSize = Vec2(64, 64);
        local posX = containerSize.x - buttonSize.x - animSize.x / 2.0;
        local posY = containerSize.y - buttonSize.y - animSize.y / 2.0;
        mLottieAnimationPanel_.setPosition(posX, posY);
        mLottieAnimationPanelBackground_.setPosition(posX + 1, posY + 1);
    }

    function initialiseGlyphOpacity_(){
        //Set all glyphs to 0 opacity initially
        if(mCurrentDialogColour_ == null) return;

        local colour = ColourValue(mCurrentDialogColour_.r, mCurrentDialogColour_.g, mCurrentDialogColour_.b, 0.0);
        for(local i = 0; i < mTotalGlyphs_; i++){
            mTextContainer_.setAnimatedGlyph(i, 0.0, 0.0, colour);
        }
    }

    function updateTextAnimation_(){
        //Animate glyphs from left to right with opacity fading
        for(local i = 0; i < mTotalGlyphs_; i++){
            if(i < mAnimationProgress_){
                //Fully visible
                local opacity = 1.0;
                local colour = mCurrentDialogColour_;
                if(colour != null){
                    colour = ColourValue(colour.r, colour.g, colour.b, 1.0);
                    mTextContainer_.setAnimatedGlyph(i, 0.0, 0.0, colour);
                }
            }else if(i < mAnimationProgress_ + 1.0){
                //Fading in - this glyph is between the last fully visible one and the next invisible one
                local fadeProgress = 1.0 - (i.tofloat() - mAnimationProgress_);
                local opacity = fadeProgress;
                local colour = mCurrentDialogColour_;
                if(colour != null){
                    colour = ColourValue(colour.r, colour.g, colour.b, opacity);
                    mTextContainer_.setAnimatedGlyph(i, 0.0, 0.0, colour);
                }
            }else{
                //Not yet visible
                local colour = mCurrentDialogColour_;
                if(colour != null){
                    colour = ColourValue(colour.r, colour.g, colour.b, 0.0);
                    mTextContainer_.setAnimatedGlyph(i, 0.0, 0.0, colour);
                }
            }
        }
    }

    function setNewDialogOptions(options){
        local containerPos = mContainerWindow_.getPosition();
        local containerSize = mContainerWindow_.getSize();
        local maxLabelWidth = ::drawable.x * 0.75;
        local yBaseOffset = containerPos.y - 10;

        //Adjust for actor title if visible
        if(mActorTitle_ != null && mActorTitle_.mWindow_.getVisible()){
            local titlePos = mActorTitle_.mWindow_.getPosition();
            local titleSize = mActorTitle_.getSize();
            yBaseOffset = titlePos.y - 10;
        }

        local maxWidth = 0;
        local buttonWidgets = [];

        //First pass: size all buttons and find max width
        for(local i = 0; i < options.len(); i++){
            local optionButton = mDialogOptionsButtons_[i];
            optionButton.setText(options[i]);
            optionButton.sizeToFit(maxLabelWidth);
            optionButton.setVisible(true);
            optionButton.setTextHorizontalAlignment(_TEXT_ALIGN_RIGHT);

            local buttonSize = optionButton.getSize();
            if(buttonSize.x > maxWidth){
                maxWidth = buttonSize.x;
            }
            buttonWidgets.push(optionButton);
        }

        //Second pass: position buttons vertically, right-aligned
        local currentYPos = yBaseOffset;
        local rightEdgeX = containerPos.x + containerSize.x + 10;
        local yOffset = 0;
        for(local i = 0; i < options.len(); i++){
            local optionButton = buttonWidgets[i];
            local buttonSize = optionButton.getSize();
            local xPos = rightEdgeX - buttonSize.x;
            optionButton.setPosition(xPos, currentYPos - yOffset - buttonSize.y);
            optionButton.applyAnimProgress(0.0);
            yOffset += buttonSize.y + 5;
        }

        //Hide remaining buttons
        for(local i = options.len(); i < 4; i++){
            mDialogOptionsButtons_[i].setVisible(false);
        }

        mNextDialogButton_.setVisible(false);

        // Start animation
        mDialogOptionsAnimFrame_ = 0;
        mDialogOptionsAnimating_ = true;
    }

    function setDialogVisible(visible){
        print("Setting dialog screen visible: " + visible.tostring());
        mWindow_.setHidden(!visible);
        if(!visible){
            mDialogIntroAnimating_ = false;
            return;
        }

        startDialogIntroAnimation_();
    }
}