::ScreenManager.Screens[Screen.COLLECTABLE_OPEN_SCREEN] = class extends ::Screen{

    mEffect_ = null;
    mFoundEffect_ = null;
    mBackButton_ = null;
    mLabel_ = null;
    mGradientPanel_ = null;
    mLabelAlpha_ = 0.0;
    mButtonAlpha_ = 0.0;
    mGradientAlpha_ = 1.0;
    mGradientFadingOut_ = false;
    mUIRevealing_ = false;
    mRising_ = false;
    mRiseFrame_ = 0;
    mRiseTotalFrames_ = 30;
    mGradientStartScreenY_ = 0.0;
    mGradientTargetScreenY_ = 0.0;
    mItemStartWorldY_ = 0.0;
    mItemTargetWorldY_ = 0.0;
    mOnClose_ = null;
    mStartPos_ = null;
    mItemScale_ = 10.0;
    mFoundMeshName_ = null;

    function setup(data){
        local winWidth = ::drawable.x;
        local winHeight = ::drawable.y;
        local insets = _window.getScreenSafeAreaInsets();

        mWindow_ = _gui.createWindow("CollectibleOpenScreen");
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setSize(::drawable);

        local gradientSize = winWidth * 0.6;
        local gradientPanel = mWindow_.createPanel();
        gradientPanel.setSize(gradientSize, gradientSize);
        gradientPanel.setCentre(winWidth / 2, winHeight / 2);
        gradientPanel.setDatablock("simpleGradient");
        gradientPanel.setClickable(false);
        mGradientPanel_ = gradientPanel;

        local label = mWindow_.createLabel();
        label.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        label.setSize(winWidth, label.getSize().y);
        label.setText("You found an item!");
        ::calculateFontWidth_(label, winWidth * 0.80);
        label.setCentre(winWidth / 2, winHeight * 0.67);
        label.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
        label.setColour(ColourValue(1, 1, 1, 0));
        mLabel_ = label;

        local button = mWindow_.createButton();
        button.setDefaultFontSize(button.getDefaultFontSize() * 1.5);
        button.setText("Back");
        button.setSkinPack("Button_blue");
        button.setExpandHorizontal(true);
        button.setMinSize(0, 100);
        button.setSize(winWidth * 0.9, 100);
        button.setPosition(winWidth * 0.05, winHeight - 100 - winWidth * 0.05 - insets.bottom);
        button.attachListenerForEvent(function(widget, action){
            if(mFoundEffect_ != null){
                mFoundEffect_.beginShrink();
                mBackButton_.setDisabled(true);
                mGradientFadingOut_ = true;
            } else {
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            }
        }, _GUI_ACTION_PRESSED, this);
        button.setColour(ColourValue(1, 1, 1, 0));
        button.setTextColour(ColourValue(1, 1, 1, 0));
        button.setDisabled(true);
        mBackButton_ = button;

        if("startPos" in data) mStartPos_ = data.startPos;
        if("itemScale" in data) mItemScale_ = data.itemScale;
        if("foundMeshName" in data) mFoundMeshName_ = data.foundMeshName;

        local effectData = {};
        if("startPos" in data) effectData.startPos <- data.startPos;
        if("itemScale" in data) effectData.itemScale <- data.itemScale;
        if("meshName" in data) effectData.meshName <- data.meshName;
        if("shrapnelMeshes" in data) effectData.shrapnelMeshes <- data.shrapnelMeshes;
        if("onClose" in data) mOnClose_ = data.onClose;

        local wrappedData = ::EffectManager.EffectData(Effect.COLLECTABLE_OPEN_EFFECT, effectData);
        local effectClass = ::EffectManager.Effects[Effect.COLLECTABLE_OPEN_EFFECT];
        mEffect_ = effectClass(wrappedData);
        mEffect_.setup(effectData);

        _window.grabCursor(false);
    }

    function update(){
        if(mEffect_ != null){
            if(!mUIRevealing_ && !mRising_ && mEffect_.getStage() == CollectibleEffectStages.BREAK){
                startFoundEffect_();
                startRise_();
            }
            local running = mEffect_.update();
            if(!running){
                mEffect_.destroy();
                mEffect_ = null;
                mUIRevealing_ = true;
            }
        }

        if(mFoundEffect_ != null){
            local running = mFoundEffect_.update();
            if(!running){
                mFoundEffect_.destroy();
                mFoundEffect_ = null;
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            }
        }

        if(mRising_){
            mRiseFrame_++;
            local p = min(1.0, mRiseFrame_.tofloat() / mRiseTotalFrames_.tofloat());
            local eased = p * p;
            local currentScreenY = mGradientStartScreenY_ + (mGradientTargetScreenY_ - mGradientStartScreenY_) * eased;
            mGradientPanel_.setCentre(::drawable.x / 2, currentScreenY);
            if(mFoundEffect_ != null){
                local currentWorldY = mItemStartWorldY_ + (mItemTargetWorldY_ - mItemStartWorldY_) * eased;
                mFoundEffect_.setCentre(0, currentWorldY);
            }
            if(p >= 1.0){
                mRising_ = false;
                mUIRevealing_ = true;
            }
        }

        if(mUIRevealing_ && mLabelAlpha_ < 1.0){
            mLabelAlpha_ = min(1.0, mLabelAlpha_ + (1.0 / 20.0));
            mLabel_.setColour(ColourValue(1, 1, 1, mLabelAlpha_));
        }

        if(mGradientFadingOut_){
            if(mGradientAlpha_ > 0.0){
                mGradientAlpha_ = max(0.0, mGradientAlpha_ - (1.0 / 30.0));
                mGradientPanel_.setColour(ColourValue(1, 1, 1, mGradientAlpha_));
            }
            if(mLabelAlpha_ > 0.0){
                mLabelAlpha_ = max(0.0, mLabelAlpha_ - (1.0 / 30.0));
                mLabel_.setColour(ColourValue(1, 1, 1, mLabelAlpha_));
            }
            if(mButtonAlpha_ > 0.0){
                mButtonAlpha_ = max(0.0, mButtonAlpha_ - (1.0 / 30.0));
                local col = ColourValue(1, 1, 1, mButtonAlpha_);
                mBackButton_.setColour(col);
                mBackButton_.setTextColour(col);
            }
        }

        if(mLabelAlpha_ >= 1.0 && mButtonAlpha_ < 1.0){
            mButtonAlpha_ = min(1.0, mButtonAlpha_ + (1.0 / 20.0));
            local col = ColourValue(1, 1, 1, mButtonAlpha_);
            mBackButton_.setColour(col);
            mBackButton_.setTextColour(col);
            if(mButtonAlpha_ >= 1.0){
                mBackButton_.setDisabled(false);
            }
        }
    }

    function startRise_(){
        mRising_ = true;
        mRiseFrame_ = 0;
        mGradientStartScreenY_ = ::drawable.y / 2;
        mGradientTargetScreenY_ = ::drawable.y * 0.35;
        mItemStartWorldY_ = 0.0;
        local targetWorldPos = ::EffectManager.getWorldPositionForWindowPos(Vec2(::drawable.x / 2, ::drawable.y * 0.35));
        mItemTargetWorldY_ = targetWorldPos.y;
    }

    function startFoundEffect_(){
        if(mFoundMeshName_ == null) return;
        local foundEffectData = {
            "meshName": mFoundMeshName_,
            "itemScale": mItemScale_,
            "targetPos": mStartPos_
        };
        local wrappedData = ::EffectManager.EffectData(Effect.COLLECTABLE_ITEM_EFFECT, foundEffectData);
        local effectClass = ::EffectManager.Effects[Effect.COLLECTABLE_ITEM_EFFECT];
        mFoundEffect_ = effectClass(wrappedData);
        mFoundEffect_.setup(foundEffectData);
    }

    function shutdown(){
        if(mEffect_ != null){
            mEffect_.destroy();
            mEffect_ = null;
        }
        if(mFoundEffect_ != null){
            mFoundEffect_.destroy();
            mFoundEffect_ = null;
        }
        if(mOnClose_ != null){
            mOnClose_();
            mOnClose_ = null;
        }
        base.shutdown();
    }
};
