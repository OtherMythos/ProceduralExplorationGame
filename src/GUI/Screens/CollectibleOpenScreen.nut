::ScreenManager.Screens[Screen.COLLECTABLE_OPEN_SCREEN] = class extends ::Screen{

    mEffect_ = null;
    mBackButton_ = null;
    mLabel_ = null;
    mLabelAlpha_ = 0.0;
    mButtonAlpha_ = 0.0;
    mUIRevealing_ = false;

    function setup(data){
        local winWidth = ::drawable.x;
        local winHeight = ::drawable.y;
        local insets = _window.getScreenSafeAreaInsets();

        mWindow_ = _gui.createWindow("CollectibleOpenScreen");
        mWindow_.setSize(::drawable);

        local gradientSize = winWidth * 0.6;
        local gradientPanel = mWindow_.createPanel();
        gradientPanel.setSize(gradientSize, gradientSize);
        gradientPanel.setCentre(winWidth / 2, winHeight / 2);
        gradientPanel.setDatablock("simpleGradient");
        gradientPanel.setClickable(false);

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
        button.setExpandHorizontal(true);
        button.setMinSize(0, 100);
        button.setSize(winWidth * 0.9, 100);
        button.setPosition(winWidth * 0.05, winHeight - 100 - winWidth * 0.05 - insets.bottom);
        button.attachListenerForEvent(function(widget, action){
            ::ScreenManager.queueTransition(null, null, mLayerIdx);
        }, _GUI_ACTION_PRESSED, this);
        button.setColour(ColourValue(1, 1, 1, 0));
        button.setTextColour(ColourValue(1, 1, 1, 0));
        button.setDisabled(true);
        mBackButton_ = button;

        local effectData = {};
        if("startPos" in data) effectData.startPos <- data.startPos;
        if("itemScale" in data) effectData.itemScale <- data.itemScale;
        if("meshName" in data) effectData.meshName <- data.meshName;
        if("shrapnelMeshes" in data) effectData.shrapnelMeshes <- data.shrapnelMeshes;

        local wrappedData = ::EffectManager.EffectData(Effect.COLLECTABLE_OPEN_EFFECT, effectData);
        local effectClass = ::EffectManager.Effects[Effect.COLLECTABLE_OPEN_EFFECT];
        mEffect_ = effectClass(wrappedData);
        mEffect_.setup(effectData);

        _window.grabCursor(false);
    }

    function update(){
        if(mEffect_ != null){
            if(!mUIRevealing_ && mEffect_.getStage() == CollectibleEffectStages.BREAK){
                mUIRevealing_ = true;
            }
            local running = mEffect_.update();
            if(!running){
                mEffect_.destroy();
                mEffect_ = null;
                mUIRevealing_ = true;
            }
        }

        if(mUIRevealing_ && mLabelAlpha_ < 1.0){
            mLabelAlpha_ = min(1.0, mLabelAlpha_ + (1.0 / 20.0));
            mLabel_.setColour(ColourValue(1, 1, 1, mLabelAlpha_));
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

    function shutdown(){
        if(mEffect_ != null){
            mEffect_.destroy();
            mEffect_ = null;
        }
        base.shutdown();
    }
};
