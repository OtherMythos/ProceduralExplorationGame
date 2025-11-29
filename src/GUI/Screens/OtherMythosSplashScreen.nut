::ScreenManager.Screens[Screen.OTHER_MYTHOS_SPLASH_SCREEN] = class extends ::Screen{

    mCount_ = 0;
    mMoveDownStartFrame_ = 0;
    mTitle_ = null;
    mPanel_ = null;
    mMovingDown_ = false;
    mTitleStartPos_ = null;
    mPanelStartPos_ = null;

    function recreate(){
        mWindow_ = _gui.createWindow("OtherMythosSplashScreen");
        mWindow_.setSize(::drawable * 1.1);
        //mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinBlack");
        mWindow_.setColour(ColourValue(0, 0, 0, 1.0));

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        local fontScale = mobile ? 2.0 : 6.0;
        local panelSize = mobile ? 75 : 200;

        mTitle_ = mWindow_.createLabel();
        mTitle_.setDefaultFontSize(mTitle_.getDefaultFontSize() * fontScale);
        mTitle_.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        mTitle_.setText("OtherMythos");
        local titleCentre = mWindow_.getSize() / 2;
        titleCentre.x += panelSize/2;
        mTitle_.setCentre(titleCentre);
        mTitleStartPos_ = mTitle_.getCentre();

        mPanel_ = mWindow_.createPanel();
        mPanel_.setSize(panelSize, panelSize);
        local panelCentre = mTitle_.getCentre();
        panelCentre.x -= mTitle_.getSize().x/2 + panelSize/2 + panelSize * 0.1;
        mPanel_.setCentre(panelCentre);
        mPanel_.setDatablock("OtherMythosLogo");
        mPanelStartPos_ = mPanel_.getCentre();

        //title.setMargin(20, 20);

        //Ensure the logo is fully loaded before showing anything.
        _graphics.waitForStreamingCompletion();
    }


    function update(){
        mCount_++;
        if(mCount_ >= 120 && !mMovingDown_){
            mMovingDown_ = true;
            mMoveDownStartFrame_ = mCount_;
        }

        if(mMovingDown_){
            local framesSinceMoveStart = mCount_ - mMoveDownStartFrame_;
            if(framesSinceMoveStart >= 80){
                //Move animation complete, transition out
                ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
            }else{
                //Calculate eased movement (0 to 1) over 80 frames
                local progress = framesSinceMoveStart / 80.0;
                local easedProgress = ::Easing.easeInExpo(progress);
                local yOffset = easedProgress * 4.0;

                //Apply movement to both title and panel
                local titlePos = mTitleStartPos_;
                titlePos.y += yOffset;
                mTitle_.setCentre(titlePos);

                local panelPos = mPanelStartPos_;
                panelPos.y += yOffset;
                mPanel_.setCentre(panelPos);

                //Fade out title and logo from frame 20 onwards
                if(framesSinceMoveStart >= 20){
                    local fadeProgress = (framesSinceMoveStart - 20) / 40.0;
                    if(fadeProgress > 1.0) fadeProgress = 1.0;
                    local fadedAlpha = 1.0 - fadeProgress;
                    mTitle_.setTextColour(ColourValue(1.0, 1.0, 1.0, fadedAlpha));
                    _hlms.getDatablock("OtherMythosLogo").setColour(1, 1, 1, fadedAlpha);
                }

                //Fade out background from frame 40 onwards
                if(framesSinceMoveStart >= 40){
                    local fadeProgress = (framesSinceMoveStart - 40) / 40.0;
                    local fadedAlpha = 1.0 - fadeProgress;
                    mWindow_.setColour(ColourValue(0, 0, 0, ::Easing.easeOutQuad(fadedAlpha)));
                }
            }
        }
    }
};