::ScreenManager.Screens[Screen.DIALOG_SCREEN] = class extends ::Screen{

    mTextContainer_ = null;
    mNextDialogButton_ = null;

    mContainerWindow_ = null;
    mFullScreenInputWindow_ = null;
    mFullScreenInputButton_ = null;

    mDialogOptionsButtons_ = null;
    mActionSetId_ = null;

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

    function receiveDialogSpokenEvent(id, data){
        setNewDialogText(data);
    }

    function receiveDialogOptionEvent(id, data){
        setNewDialogOptions(data);
    }

    function receiveDialogMetaEvent(id, data){
        if("ended" in data && data.ended){
            ::ScreenManager.backupScreen(mLayerIdx);
            //setDialogVisible(false);
        }

        if("started" in data && data.started){
            setDialogVisible(true);
        }
    }

    function nextButtonPressed(widget, action){
        requestNextDialog();
    }

    function optionButtonPressed(widget, action){
        ::Base.mDialogManager.notifyOption(widget.getUserId());
        foreach(i in mDialogOptionsButtons_){
            i.setVisible(false);
        }

        mNextDialogButton_.setVisible(true);
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

    function checkShowAnimation_(){
        if(!mMobileInterface_) return;

        mShowLottieAnimation_ = true;
        mLottieAnimationPanel_.setVisible(true);
        mLottieAnimationPanelBackground_.setVisible(true);
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

        mContainerWindow_.setClickable(!mobile);

        mTextContainer_ = mContainerWindow_.createAnimatedLabel();
        mTextContainer_.setText(" ");

        mNextDialogButton_ = mContainerWindow_.createButton();
        mNextDialogButton_.setText("Next");
        mNextDialogButton_.attachListenerForEvent(nextButtonPressed, _GUI_ACTION_PRESSED, this);
        mNextDialogButton_.setVisible(!mobile);

        local buttonSize = mNextDialogButton_.getSize();
        //buttonSize *= 2;
        local winSize = mContainerWindow_.getSizeAfterClipping();
        mNextDialogButton_.setPosition(winSize.x - buttonSize.x, winSize.y - buttonSize.y);

        for(local i = 0; i < 4; i++){
            local button = mWindow_.createButton();
            button.setText(" ");
            button.setVisible(false);
            button.setUserId(i);
            button.attachListenerForEvent(optionButtonPressed, _GUI_ACTION_PRESSED, this);
            mDialogOptionsButtons_[i] = button;
        }

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
        mTextContainer_.setText(targetText, false);

        if(richText != null){
            mTextContainer_.setRichText(richText);
            mCurrentDialogColour_ = ColourValue(1, 1, 1, 1);
        }else{
            mCurrentDialogColour_ = ColourValue(1, 1, 1, 1);
            mTextContainer_.setTextColour(1, 1, 1, 1);
        }

        mTextContainer_.sizeToFit(mContainerWindow_.getSize().x * 0.95);
        mTotalGlyphs_ = targetText.len();
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
        local BUTTON_SIZE = 50;
        local containerPos = mContainerWindow_.getPosition();
        local containerSize = mContainerWindow_.getSize();
        for(local i = 0; i < 4; i++){
            local button = mDialogOptionsButtons_[i];
            if(i < options.len()){
                button.setText(options[i]);
                button.setVisible(true);
                local buttonWidth = button.getSize().x * 1.5;
                button.setSize(buttonWidth, BUTTON_SIZE);

                button.setPosition(containerPos.x + containerSize.x - buttonWidth, containerPos.y - BUTTON_SIZE * (options.len() - i));
            }else{
                button.setVisible(false);
            }
        }

        mNextDialogButton_.setVisible(false);
        _gui.reprocessMousePosition();
    }

    function setDialogVisible(visible){
        print("Setting dialog screen visible: " + visible.tostring());
        mWindow_.setHidden(!visible);
    }
}