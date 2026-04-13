::ScreenManager.Screens[Screen.READABLE_CONTENT_SCREEN] = class extends ::Screen{

    mWindow_ = null;
    mReadableContent_ = null;
    mActionSetId_ = null;
    mMeshName_ = null;

    //Background mesh render
    mBgRenderIcon_ = null;
    mBgPanel_ = null;
    mBgStartPos_ = null;
    mBgEndPos_ = null;
    mBgInitialSize_ = null;
    mBgFillSize_ = null;

    mAnimTime_ = 0;
    mAnimFrame_ = 0;

    //Close animation state
    mIsClosing_ = false;
    mCloseAnimFrame_ = 0;
    mContentPanel_ = null;
    mContentPos_ = null;
    mContentShown_ = false;
    mContentFadeFrame_ = 0;
    mContentLabels_ = null;
    mButtonContainer_ = null;

    static SLIDE_FRAMES = 30;
    static ZOOM_FRAMES = 25;
    static CONTENT_SHOW_FRAME = 53;
    static CONTENT_FADE_FRAMES = 20;

    function setup(data){
        createBackgroundScreen_();
        createBackgroundCloseButton_();

        if(data != null && data.rawin("content")){
            mReadableContent_ = data.content;
        }else{
            mReadableContent_ = [
                "test",
                "second line",
                "third line"
            ];
        }

        mMeshName_ = (data != null && data.rawin("meshName")) ? data.meshName : "readables.noteScrap.voxMesh";
        mAnimFrame_ = 0;
        mAnimTime_ = 0;
        mContentShown_ = false;

        mWindow_ = _gui.createWindow("ReadableContentScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setVisualsEnabled(false);
        mWindow_.setBreadthFirst(true);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setClickable(false);

        //Background mesh panel (created first so it renders behind content)
        setupBgMesh_();

        //Content panel in centre with grey skin
        local contentSize = ::drawable.copy();
        contentSize.x *= 0.8;
        contentSize.y *= 0.5;
        mContentPos_ = Vec2(
            (::drawable.x - contentSize.x) * 0.5,
            (::drawable.y - contentSize.y) * 0.5
        );

        mContentPanel_ = mWindow_.createWindow("ReadableContentPanel");
        mContentPanel_.setSize(contentSize);
        mContentPanel_.setSkinPack("Panel_midGrey");
        mContentPanel_.setPosition(mContentPos_);
        mContentPanel_.setBreadthFirst(true);
        mContentPanel_.setOpacity(0);

        mContentLabels_ = [];
        local layoutLine = _gui.createLayoutLine();

        foreach(i in mReadableContent_){
            local label = mContentPanel_.createLabel();
            label.setText(i);
            label.sizeToFit(contentSize.x * 0.9);
            label.setShadowOutline(true, ColourValue(0, 0, 0), Vec2(2, 2));
            label.setTextColour(ColourValue(1, 1, 1, 0));  //Start with 0 opacity
            mContentLabels_.append(label);
            layoutLine.addCell(label);
        }

        layoutLine.setSize(contentSize);
        layoutLine.layout();

        constructButtons_();

        mActionSetId_ = ::InputManager.pushActionSet(InputActionSets.MENU);
    }

    function setupBgMesh_(){
        local initDim = ::drawable.x * 0.45;
        mBgInitialSize_ = Vec2(initDim, initDim);
        local fillDim = max(::drawable.x, ::drawable.y) * 0.65;
        mBgFillSize_ = Vec2(fillDim, fillDim);

        local centreX = ::drawable.x * 0.5;
        local centreY = ::drawable.y * 0.5;
        mBgEndPos_ = Vec2(centreX, centreY);
        mBgStartPos_ = Vec2(centreX, ::drawable.y + mBgInitialSize_.y * 0.5);

        mBgRenderIcon_ = ::RenderIconManager.createIcon(mMeshName_, true, true, mLayerIdx);
        mBgRenderIcon_.setSize(mBgInitialSize_.x, mBgInitialSize_.y);
        mBgRenderIcon_.setPosition(mBgStartPos_);

        local orient = Quat();
        orient += Quat(0.5, ::Vec3_UNIT_Y);
        orient += Quat(1.0, ::Vec3_UNIT_X);
        mBgRenderIcon_.setOrientation(orient);

        local datablock = mBgRenderIcon_.getDatablock();
        if(datablock != null){
            mBgPanel_ = mWindow_.createPanel();
            mBgPanel_.setSize(mBgInitialSize_);
            mBgPanel_.setDatablock(datablock);
            mBgPanel_.setClickable(false);
            mBgPanel_.setCentre(mBgStartPos_.x, mBgStartPos_.y);
        }
    }

    function constructButtons_(){
        local insets = _window.getScreenSafeAreaInsets();
        local buttonMargin = 10;
        local buttonPanelHeight = 80;
        local buttonY = ::drawable.y - insets.bottom - buttonMargin - buttonPanelHeight;

        //Create inner window for buttons layout
        local buttonContainer = mWindow_.createWindow("ReadableButtonContainer");
        buttonContainer.setSize(::drawable.x, ::drawable.y);
        buttonContainer.setVisualsEnabled(true);
        buttonContainer.setSkinPack("Panel_midGrey");
        buttonContainer.setBreadthFirst(true);
        mButtonContainer_ = buttonContainer;

        local mHorizontalLayout_ = _gui.createLayoutLine(_LAYOUT_HORIZONTAL);

        local buttonLabels = [
            "Back",
            "Previous",
            "Next"
        ];
        local buttonFunctions = [
            function(widget, action){
                closeScreen();
            },
            function(widget, action){

            },
            function(widget, action){

            },
        ];

        local buttons = [];
        foreach(c, i in buttonLabels){
            local button = buttonContainer.createButton();
            button.setText(i);
            button.attachListenerForEvent(buttonFunctions[c], _GUI_ACTION_PRESSED, this);
            buttons.append(button);
            mHorizontalLayout_.addCell(button);
            if(c == 0) button.setFocus();
        }

        local maxHeight = ::evenOutButtonsForHeight(buttons);

        mHorizontalLayout_.setMarginForAllCells(10, 0);
        mHorizontalLayout_.setPosition(-10, 0);
        mHorizontalLayout_.layout();

        //Resize button container to fit content
        buttonContainer.setSize(::drawable.x, maxHeight);
        buttonContainer.sizeScrollToFit();

        buttonContainer.setSize(buttonContainer.calculateChildrenSize());

        buttonContainer.setPosition((::drawable.x - buttonContainer.getSize().x) * 0.5, mContentPanel_.getPosition().y + mContentPanel_.getSize().y + 10);
        buttonContainer.setVisible(false);
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isScreenTop(mLayerIdx) && !mIsClosing_) closeScreen();
        }
        updateAnimation_();
    }

    function updateAnimation_(){
        if(mBgRenderIcon_ == null) return;

        //Handle close animation
        if(mIsClosing_){
            updateCloseAnimation_();
            return;
        }

        mAnimFrame_++;
        mAnimTime_ += 0.05;

        //Phase 1: slide up from off-screen to centre
        if(mAnimFrame_ <= SLIDE_FRAMES){
            local p = min(1.0, mAnimFrame_.tofloat() / SLIDE_FRAMES.tofloat());
            local eased = ::Easing.easeOutBack(p);
            local currentPos = mBgStartPos_ + (mBgEndPos_ - mBgStartPos_) * eased;
            mBgRenderIcon_.setPosition(currentPos);
            mBgRenderIcon_.setSize(mBgInitialSize_.x, mBgInitialSize_.y);
            if(mBgPanel_ != null){
                mBgPanel_.setSize(mBgInitialSize_);
                mBgPanel_.setCentre(currentPos.x, currentPos.y);
                mBgPanel_.setOpacity(0.95);
            }
            //Fade in background screen during phase 1
            if(mBackgroundWindow_ != null){
                local bgOpacity = p * 0.8;
                mBackgroundWindow_.setColour(ColourValue(1.0, 1.0, 1.0, bgOpacity));
            }
        //Phase 2: zoom to fill the screen
        } else if(mAnimFrame_ <= SLIDE_FRAMES + ZOOM_FRAMES){
            local p = min(1.0, (mAnimFrame_ - SLIDE_FRAMES).tofloat() / ZOOM_FRAMES.tofloat());
            local eased = ::Easing.easeInOutCubic(p);
            local currentSize = mBgInitialSize_ + (mBgFillSize_ - mBgInitialSize_) * eased;
            mBgRenderIcon_.setPosition(mBgEndPos_);
            mBgRenderIcon_.setSize(currentSize.x, currentSize.y);
            if(mBgPanel_ != null){
                mBgPanel_.setSize(currentSize);
                mBgPanel_.setCentre(mBgEndPos_.x, mBgEndPos_.y);
                mBgPanel_.setOpacity(0.95);
            }
            //Maintain background opacity during phase 2
            if(mBackgroundWindow_ != null){
                mBackgroundWindow_.setColour(ColourValue(1.0, 1.0, 1.0, 0.8));
            }
        }

        //Reveal content panel once zoom has nearly finished
        if(!mContentShown_ && mAnimFrame_ >= CONTENT_SHOW_FRAME){
            mContentShown_ = true;
            mContentPanel_.setPosition(mContentPos_);
            mContentFadeFrame_ = 0;
        }

        //Fade in content panel and labels
        if(mContentShown_ && mContentFadeFrame_ < CONTENT_FADE_FRAMES){
            mContentFadeFrame_++;
            local p = min(1.0, mContentFadeFrame_.tofloat() / CONTENT_FADE_FRAMES.tofloat());
            local eased = ::Easing.easeInOutCubic(p);
            local opacity = eased * 0.95;
            mContentPanel_.setOpacity(opacity);

            //Fade in labels
            if(mContentLabels_ != null){
                foreach(label in mContentLabels_){
                    label.setTextColour(ColourValue(1, 1, 1, opacity));
                }
            }
        }

        //Show button container once content fade completes
        if(mContentShown_ && mContentFadeFrame_ >= CONTENT_FADE_FRAMES && mButtonContainer_ != null){
            mButtonContainer_.setVisible(true);
        }

        //Idle spin - half speed
        local rotY = Quat(sin(mAnimTime_ * 0.75) * 0.05, ::Vec3_UNIT_Y);
        local baseOrient = Quat();
        baseOrient += Quat(0.5, ::Vec3_UNIT_Y);
        baseOrient += Quat(1.0, ::Vec3_UNIT_X);
        local animOrient = baseOrient;
        animOrient += rotY;
        mBgRenderIcon_.setOrientation(animOrient);
    }

    function updateCloseAnimation_(){
        if(mBgRenderIcon_ == null) return;

        //Hide buttons immediately on first close frame
        if(mCloseAnimFrame_ == 0 && mButtonContainer_ != null){
            mButtonContainer_.setVisible(false);
        }

        mCloseAnimFrame_++;

        //Shrink from fill size back to initial size with fade out
        if(mCloseAnimFrame_ <= ZOOM_FRAMES){
            local p = min(1.0, mCloseAnimFrame_.tofloat() / ZOOM_FRAMES.tofloat());
            local eased = ::Easing.easeInOutCubic(p);
            local currentSize = mBgFillSize_ + (mBgInitialSize_ - mBgFillSize_) * eased;
            mBgRenderIcon_.setPosition(mBgEndPos_);
            mBgRenderIcon_.setSize(currentSize.x, currentSize.y);
            if(mBgPanel_ != null){
                mBgPanel_.setSize(currentSize);
                mBgPanel_.setCentre(mBgEndPos_.x, mBgEndPos_.y);
                //Fade out opacity
                local opacity = 1.0 - p;
                mBgPanel_.setOpacity(opacity);
            }

            //Fade out labels
            if(mContentLabels_ != null){
                local opacity = 1.0 - p;
                foreach(label in mContentLabels_){
                    label.setTextColour(ColourValue(1, 1, 1, opacity));
                }
            }

            //Fade out background window
            if(mBackgroundWindow_ != null){
                local opacity = 1.0 - p;
                mBackgroundWindow_.setColour(ColourValue(1.0, 1.0, 1.0, opacity * 0.8));
            }
        } else {
            //Close animation complete, perform actual close
            finishClose_();
        }
    }

    function finishClose_(){
        ::ScreenManager.backupScreen(mLayerIdx);
        ::Base.mExplorationLogic.unPauseExploration();
    }

    function closeScreen(){
        if(mIsClosing_) return;
        mIsClosing_ = true;
        mCloseAnimFrame_ = 0;
        mContentPanel_.setPosition(Vec2(-10000, -10000));
    }

    function shutdown(){
        if(mBgPanel_ != null){
            mBgPanel_.setDatablock("simpleGrey");
            mBgPanel_ = null;
        }
        if(mBgRenderIcon_ != null){
            mBgRenderIcon_.destroy();
            mBgRenderIcon_ = null;
        }
        base.shutdown();
        ::InputManager.popActionSet(mActionSetId_);
    }
};