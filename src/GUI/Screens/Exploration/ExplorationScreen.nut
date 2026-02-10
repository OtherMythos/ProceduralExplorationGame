enum ExplorationBusEvents{
    TRIGGER_ITEM,
    TRIGGER_ENCOUNTER
};

enum ExplorationScreenWidgetType{
    STATS_CONTAINER,
    MOVES_CONTAINER,
    MINIMAP,
    PAUSE_BUTTON,
    CAMERA_BUTTON,
    INVENTORY_INDICATOR,
    COMPASS,
    ZOOM_SLIDER,
    DIRECTION_JOYSTICK,

    MAX
}

::ScreenManager.Screens[Screen.EXPLORATION_SCREEN] = class extends ::Screen{

    mWorldMapDisplay_ = null;
    mExplorationProgressBar_ = null;
    mLogicInterface_ = null;
    mExplorationItemsContainer_ = null;
    mExplorationEnemiesContainer_ = null;
    mExplorationMovesContainer_ = null;
    mExplorationStatsContainer_ = null;
    mExplorationPlayerActionsContainer_ = null;
    mMoneyCounter_ = null;
    mExplorationBus_ = null;
    mPlaceHelperLabel_ = null;
    mPlaceHelperButton_ = null;
    mCurrentPlace_ = null;
    mScrapAllButton_ = null;
    mPauseButton = null;
    mZoomModifierButton = null;
    mCameraButton = null;
    mPlayerDirectButton = null;
    mPlayerDirectJoystick_ = null;
    mPlayerTapButton = null;
    mPlayerTapButtonActive = false;
    mSwipeAttackButton_ = null;
    mSwipeTapStartPos_ = null;
    mSwipeTapEndPos_ = null;
    mSwipeTapActive_ = false;
    mSwipeCompassPanel_ = null;
    mSwipeCompassRotation_ = 0.0;
    mSwipeCompassTargetOpacity_ = 0.0;
    mSwipeCompassCurrentOpacity_ = 0.0;
    mSwipeHoldTimer_ = 0;
    static SWIPE_HOLD_THRESHOLD = 60; //1 second at 60fps
    static SWIPE_HOLD_REPEAT_INTERVAL = 15; //Repeat attack every 0.25 seconds
    mDiscoverLevelUpScreen_ = null;
    mInventoryWidget_ = null;
    mLayoutLine_ = null;
    mZoomLines_ = null;
    mMobileActionInfo_ = null;
    mFoundItemIconsManager_ = null;

    mPlayerDied_ = 0;

    mTargetTopInfoOpacity_ = 1.0;
    mTopInfoAnim_ = 1.0;

    mAnimator_ = null;
    mCompassAnimator_ = null;

    mScreenInputCheckList_ = null;

    mInputBlockerWindow_ = null;

    mInsideGateway_ = false;
    mTooltipManager_ = null;

    mWorldStatsScreen_ = null;

    mExplorationScreenWidgetType_ = null;

    ExplorationScreenZoomLines = class{
        mZoomLinesPanel_ = null;
        mZoomWindow_ = null;

        mLineSize_ = null;
        mDatablock_ = null;

        MAX_OPACITY_COUNT = 60;
        mCurrentOpacityCount_ = 0;

        mCurrentOpacity_ = 0.2;
        mTargetOpacity_ = 0.2;

        constructor(parent){
            mLineSize_ = Vec2(70, 1240);

            mZoomWindow_ = parent.createWindow();
            mZoomWindow_.setVisualsEnabled(false);
            mZoomLinesPanel_ = mZoomWindow_.createPanel();
            mDatablock_ = _hlms.getDatablock("guiExplorationZoomLines");
            mDatablock_.setUseColour(true);
            mDatablock_.setColour(1, 1, 1, 0.2);
            mZoomLinesPanel_.setDatablock(mDatablock_);
            mZoomLinesPanel_.setSize(mLineSize_);
            mZoomLinesPanel_.setClickable(false);
            mZoomWindow_.setClickable(false);
            mZoomWindow_.setSize(70, 640);
            mZoomWindow_.setClipBorders(0, 0, 0, 0);
        }

        function update(){
            local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
            local currentZoom = currentWorld.mCurrentZoomLevel_;
            mZoomLinesPanel_.setPosition(0, -(currentZoom - currentWorld.MIN_ZOOM));

            if(mCurrentOpacityCount_ >= 0){
                if(!currentWorld.isMouseStateActive(WorldMousePressContexts.ZOOMING)){
                    mCurrentOpacityCount_--;
                }
            }

            if(mCurrentOpacityCount_ <= 0){
                mTargetOpacity_ = 0.2;
            }else{
                mTargetOpacity_ = 1.0;
            }

            mCurrentOpacity_ = ::accelerationClampCoordinate_(mCurrentOpacity_, mTargetOpacity_);

            mDatablock_.setColour(1, 1, 1, mCurrentOpacity_);
        }

        function setVisible(visible){
            mZoomWindow_.setVisible(visible);
        }

        function setRecentTouchInteraction(){
            mCurrentOpacityCount_ = MAX_OPACITY_COUNT;
        }

        function getPosition(){
            return mZoomWindow_.getPosition();
        }

        function getSize(){
            return mZoomWindow_.getSize();
        }

        function setPosition(pos){
            mZoomWindow_.setPosition(pos);
        }

        function setSize(size){
            mZoomWindow_.setSize(size);
        }
    }



    ExplorationScreenMobileActionInfo = class{

        mParent_ = null;
        mLabel_ = null;
        mAnimationPanel_ = null;
        mAnimationPanelBackground_ = null;
        mButton_ = null;
        mDisabledPanel_ = null;

        mLottieAnimation_ = null;
        mLottieAnimationSecond_ = null;

        mDatablock_ = null;
        mBackgroundDatablock_ = null;

        mTargetAnimation_ = 0.0;
        mAnim_ = 1.0;
        mVisible_ = true;
        mIsActionActive_ = true;

        constructor(parent){
            mButton_ = parent.createButton();
            mButton_.attachListenerForEvent(function(widget, action){
                ::Base.mActionManager.executeSlot(0);
            }, _GUI_ACTION_PRESSED);
            mButton_.setSize(10, 10);
            mButton_.setVisualsEnabled(false);

            mParent_ = parent;
            mLabel_ = parent.createLabel();
            mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, 1), Vec2(2, 2));
            //mLabel_.setDefaultFontSize(mLabel_.getDefaultFontSize() * 1.5);
            mLabel_.setText("Descend");

            local animSize = Vec2(64, 64);
            mAnimationPanelBackground_ = parent.createPanel();
            mAnimationPanelBackground_.setSize(animSize);
            mAnimationPanel_ = parent.createPanel();
            mAnimationPanel_.setSize(animSize);

            mDisabledPanel_ = parent.createPanel();
            mDisabledPanel_.setSize(animSize * 0.75);
            mDisabledPanel_.setDatablock(_hlms.getDatablock("redCross"));
            mDisabledPanel_.setClickable(false);
            mDisabledPanel_.setVisible(false);
            mDisabledPanel_.setColour(ColourValue(1, 1, 1, 0.75));

            mLabel_.setClickable(false);
            mAnimationPanel_.setClickable(false);
            mAnimationPanelBackground_.setClickable(false);

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
            mAnimationPanel_.setDatablock(datablock);
            mDatablock_ = datablock;
            datablock = lottieMan.getDatablockForAnim(mLottieAnimationSecond_);
            mAnimationPanelBackground_.setDatablock(datablock);
            mBackgroundDatablock_ = datablock;

            mLabel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
            mAnimationPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
            mAnimationPanelBackground_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
            mDisabledPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);

            reposition_();
        }

        function reposition_(){
            local winPos = mParent_.getSize() / 2;
            winPos.y -= 100;
            winPos.x += mAnimationPanel_.getSize().x / 4;
            mLabel_.setCentre(winPos);

            winPos = mLabel_.getPosition();
            winPos.x -= mAnimationPanel_.getSize().x * 0.9;
            winPos.y -= mAnimationPanel_.getSize().y / 8;
            mAnimationPanel_.setPosition(winPos);
            winPos += Vec2(1, 1);
            mAnimationPanelBackground_.setPosition(winPos);

            {
                local labelCentre = mLabel_.getCentre();
                local labelPos = mLabel_.getPosition();
                local disabledPos = Vec2(labelPos.x - mDisabledPanel_.getSize().x / 2, labelCentre.y);
                mDisabledPanel_.setCentre(disabledPos);
            }

            local totalSize =  (mLabel_.getPosition() + mLabel_.getSize()) - mAnimationPanel_.getPosition();
            mButton_.setSize(totalSize);
            mButton_.setPosition(mAnimationPanel_.getPosition());
        }

        function setOpacity(opacity){
            //mLabel_.setVisible(visible);
            //mAnimationPanel_.setVisible(visible);
            //mAnimationPanelBackground_.setVisible(visible);
            local labelOpacity = opacity;
            local labelColour = ColourValue(1, 1, 1, labelOpacity);
            if(!mIsActionActive_){
                labelOpacity = opacity * 0.75;
                labelColour = ColourValue(1, 0.5, 0.5, labelOpacity);
            }
            mLabel_.setTextColour(labelColour);
            mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, labelOpacity), Vec2(2, 2));

            //mDatablock_.setUseColour(true);
            //mAnimationPanel_.setColour(ColourValue(1, 1, 1, opacity));
            //TODO I wasn't able to fade in the opacity due to how the blendblocks are setup.
            local animVisible = (opacity >= 0.5 && mVisible_ && mIsActionActive_);
            mAnimationPanel_.setVisible(animVisible);
            mAnimationPanelBackground_.setVisible(animVisible);
            local disabledVisible = (opacity >= 0.5 && mVisible_ && !mIsActionActive_);
            mDisabledPanel_.setVisible(disabledVisible);
            mButton_.setVisible(mVisible_);
            //mBackgroundDatablock_.setUseColour(true);
            //mAnimationPanelBackground_.setColour(ColourValue(1, 1, 1, opacity));
        }

        function update(){
            mAnim_ = ::accelerationClampCoordinate_(mAnim_, mTargetAnimation_, 0.1);
            setOpacity(mAnim_);
        }

        function actionsChanged(data, allEmpty){
            //setVisible_(!allEmpty);
            if(allEmpty){
                mTargetAnimation_ = 0.0;
                return;
            }
            mTargetAnimation_ = 1.0;

            mLabel_.setText(data[0].tostring());
            mIsActionActive_ = data[0].mIsActive[0];
            reposition_();
        }

        function setVisible(visible){
            mVisible_ = visible;
            mLabel_.setVisible(visible);
            mAnimationPanel_.setVisible(visible);
            mAnimationPanelBackground_.setVisible(visible);
            mDisabledPanel_.setVisible(visible);
            mButton_.setVisible(visible);
        }

    };

    ExplorationScreenAnimator = class{
        mInventoryParams_ = null;
        mInventoryColour_ = null;

        static GREEN = 0;
        static YELLOW = 1;
        static RED = 2;

        mAnimCount_ = 1.0;
        mPrevPercentage_ = 0.0;
        mTargetPercentage_ = 0.0;

        constructor(){
            local material = _graphics.getMaterialByName("Postprocess/InventoryRing");
            local gpuParams = material.getFragmentProgramParameters(0, 0);
            mInventoryParams_ = gpuParams;

            setInventoryColour_(GREEN);
        }

        function update(){
            if(mAnimCount_ >= 1.0) return;
            mAnimCount_ += 0.05;
            if(mAnimCount_ > 1.0) mAnimCount_ = 1.0;
            //mInventoryParams_.setNamedConstant("radian", mCount_ % (PI * 2));

            local animPercentage = mPrevPercentage_ + (mTargetPercentage_ - mPrevPercentage_) * mAnimCount_;
            setInventoryPercentage_(animPercentage);
        }

        function setInventoryPercentage_(percentage){
            local c = GREEN;
            if(percentage <= 0.5){
                c = GREEN;
            }else if(percentage > 0.5 && percentage < 1.0){
                c = YELLOW;
            }else{
                c = RED;
            }
            setInventoryColour_(c);
            mInventoryParams_.setNamedConstant("radian", percentage * (PI * 2));
        }

        function animateToInventoryPercentage(percentage){
            mAnimCount_ = 0.0;
            mPrevPercentage_ = mTargetPercentage_;
            mTargetPercentage_ = percentage;
        }

        function setInventoryColour_(col){
            if(col == mInventoryColour_) return;

            local c = null;
            if(col == GREEN){
                c = Vec3(0, 1, 0);
            }
            else if(col == YELLOW){
                c = Vec3(1, 1, 0);
            }
            else if(col == RED){
                c = Vec3(1, 0, 0);
            }
            mInventoryParams_.setNamedConstant("colour", c);

            mInventoryColour_ = col;
        }
    }

    WorldStatsScreen = class{
        mParent_ = null;
        mWindow_ = null;
        mInfoLabel_ = null;
        constructor(parent){
            mParent_ = parent;

        }
        function setup(){
            mWindow_ = mParent_.createWindow("WorldStatsScreen");
            mWindow_.setSize(100, 100);
            mWindow_.setVisualsEnabled(false);
            mWindow_.setSkinPack("WindowSkinNoBorder");

            mInfoLabel_ = mWindow_.createLabel();

            displayWorldStats(" ");

            _event.subscribe(Event.ACTIVE_WORLD_CHANGE, receiveWorldChange, this);
        }
        function shutdown(){
            _gui.destroy(mWindow_);
            _event.unsubscribe(Event.ACTIVE_WORLD_CHANGE, receiveWorldChange, this);
        }
        function displayWorldStats(stats){
            mInfoLabel_.setText(stats != null ? stats : " ");

            local labelSize = mInfoLabel_.getSize();
            mWindow_.setPosition(10, _window.getHeight() - labelSize.y);
            mWindow_.setSize(labelSize);
        }
        function setVisible(vis){
            if(mWindow_ == null){
                setup();
            }
            mWindow_.setVisible(vis);
        }
        function receiveWorldChange(id, data){
            local statsString = data.getStatsString();
            displayWorldStats(statsString);
        }
    };

    DiscoverLevelUpScreen = class{
        mParent_ = null;
        mWindow_ = null;

        mBar_ = null;
        //mBar_ = null;
        //mLabel_ = null;

        mFrame_ = 0;
        mPercentAnimCurrent_ = 0;
        mPercentAnimFinal_ = 0;
        mFutureLevel_ = 0;
        mCompleteLevel_ = 0;
        mAnimFrameCount_ = 0.005;

        constructor(parent){
            mParent_ = parent;
        }
        function setup(){
            mWindow_ = mParent_.createWindow("WorldDiscoverLevelUpScreen");
            mWindow_.setSize(200, 200);
            mWindow_.setPosition(0, 0);
            mWindow_.setVisualsEnabled(false);
            mWindow_.setSkinPack("WindowSkinNoBorder");
            mWindow_.setVisible(false);

            local layoutLine = _gui.createLayoutLine();

            mBar_ = ::GuiWidgets.ExplorationDiscoverLevelBarWidget(mWindow_);
            mBar_.addToLayout(layoutLine);

            layoutLine.layout();
            mBar_.notifyLayout();

            _event.subscribe(Event.BIOME_DISCOVER_STATS_CHANGED, biomeStatsChanged, this);
        }
        function setPosition(pos){
            mWindow_.setPosition(pos);
        }
        function update(){
            mFrame_++;
            if(mFrame_ > 300) return;
            if(mFrame_ == 300){
                mWindow_.setVisible(false);
                return;
            }
            if(mFrame_ == 100){
                mBar_.setCounter(mFutureLevel_, mCompleteLevel_);
            }
            if(mFrame_ > 100){
                if(mPercentAnimCurrent_ <= mPercentAnimFinal_){
                    mPercentAnimCurrent_ += mAnimFrameCount_;
                    mBar_.setSecondaryPercentage(mPercentAnimCurrent_);
                }
            }

        }
        function shutdown(){
            _event.unsubscribe(Event.BIOME_DISCOVER_STATS_CHANGED, biomeStatsChanged, this);
        }

        function biomeStatsChanged(id, data){
            mBar_.setText(data.biome.getName());
            mBar_.setPercentage(data.percentageCurrent);
            mBar_.setSecondaryPercentage(data.percentageCurrent);
            mFutureLevel_ = data.levelProgress;
            mCompleteLevel_ = data.completeLevel;
            mBar_.setCounter(mFutureLevel_-1, mCompleteLevel_);
            mPercentAnimCurrent_ = data.percentageCurrent;
            mPercentAnimFinal_ = data.percentageFuture;
            mAnimFrameCount_ = (mPercentAnimFinal_ - mPercentAnimCurrent_).tofloat() / 30.0;
            mFrame_ = 0;
            mWindow_.setSize(mWindow_.calculateChildrenSize());
            //mWindow_.setVisible(true && !::Base.isProfileActive(GameProfile.SCREENSHOT_MODE));
            mWindow_.setVisible(false);
        }

    };

    FoundItemIconsManager = class{
        mParentWindow_ = null;
        mItemWidgets_ = null;
        mWidgetTimeouts_ = null;
        mBasePosition_ = Vec2(0, 0);

        static MAX_DISPLAYED_ITEMS = 5;
        static ITEM_TIMEOUT_FRAMES = 200;

        constructor(parentWindow){
            mParentWindow_ = parentWindow;
            mItemWidgets_ = [];
            mWidgetTimeouts_ = [];
        }

        function addItem(itemDef){
            if(mItemWidgets_.len() >= MAX_DISPLAYED_ITEMS){
                //Remove the oldest item
                local oldestWidget = mItemWidgets_.remove(0);
                mWidgetTimeouts_.remove(0);
                oldestWidget.shutdown();
            }

            //Create new widget
            local newWidget = ::GuiWidgets.FoundItemWidget(mParentWindow_, itemDef, 0.3);
            mItemWidgets_.append(newWidget);
            mWidgetTimeouts_.append(0);

            updatePositions_();
        }

        function updatePositions_(){
            local yOffset = 0;
            for(local i = 0; i < mItemWidgets_.len(); i++){
                local widgetSize = mItemWidgets_[i].getSize();
                local yPos = mBasePosition_.y + yOffset;
                mItemWidgets_[i].setPosition(Vec2(mBasePosition_.x, yPos));
                yOffset += widgetSize.y;
            }
        }

        function update(){
            //Update all widgets and their timeouts
            local i = 0;
            while(i < mItemWidgets_.len()){
                mItemWidgets_[i].update();
                mWidgetTimeouts_[i]++;
                if(mWidgetTimeouts_[i] >= ITEM_TIMEOUT_FRAMES){
                    //Start removal animation
                    if(!mItemWidgets_[i].mRemovalAnimationActive_){
                        mItemWidgets_[i].startRemovalAnimation();
                    }else{
                        //Update removal animation
                        mItemWidgets_[i].mRemovalAnimationProgress_ += 1.0 / (::GuiWidgets.FoundItemWidget.REMOVAL_ANIMATION_DURATION * 60.0);
                        if(mItemWidgets_[i].mRemovalAnimationProgress_ >= 1.0){
                            //Animation complete, remove widget
                            local oldWidget = mItemWidgets_.remove(i);
                            mWidgetTimeouts_.remove(i);
                            oldWidget.shutdown();
                            updatePositions_();
                            continue;
                        }
                        updateRemovalAnimationForWidget_(mItemWidgets_[i]);
                    }
                    i++;
                }else{
                    i++;
                }
            }
        }

        function updateRemovalAnimationForWidget_(widget){
            //Ease out cubic for smooth removal
            local easeProgress = 1.0 - pow(1.0 - widget.mRemovalAnimationProgress_, 3.0);

            //Animate upward by the widget size
            local upwardOffset = widget.getSize().y * widget.mRemovalAnimationProgress_;
            local newPos = widget.mPosition_ - Vec2(0, upwardOffset);

            //Animate opacity to 0
            local opacity = 1.0 - easeProgress;

            //Animate scale from 1.0 to 0.0
            local scale = 1.0 - easeProgress;

            //TODO remove direct access to widget members
            if(widget.mRenderIcon_ != null){
                local iconSize = widget.mFoundAnimationFinalSize_ * scale;
                widget.mRenderIcon_.setPosition(Vec2(newPos.x + widget.mFullSize_.x / 2, newPos.y + widget.mMeshSize_.y / 2));
                widget.mRenderIcon_.setSize(iconSize.x, iconSize.y);
            }

            if(widget.mLabel_ != null){
                widget.mLabel_.setPosition(newPos.x + (widget.mFullSize_.x - widget.mLabel_.getSize().x) / 2, newPos.y + widget.mMeshSize_.y + ::GuiWidgets.FoundItemWidget.LABEL_OFFSET_Y);
                widget.mLabel_.setTextColour(1, 1, 1, opacity);
            }

            if(widget.mGradientPanel_ != null){
                widget.mGradientPanel_.setColour(ColourValue(1, 1, 1, opacity * 0.5));
            }

            if(widget.mDebugPanel_ != null){
                widget.mDebugPanel_.setPosition(newPos);
            }

            if(widget.mDebugMeshPanel_ != null){
                local meshPanelPos = newPos + (widget.mFullSize_ - widget.mMeshSize_) / 2;
                meshPanelPos.y = newPos.y;
                widget.mDebugMeshPanel_.setPosition(meshPanelPos);
            }
        }

        function setBasePosition(pos){
            mBasePosition_ = pos;
            updatePositions_();
        }

        function setVisible(visible){
            foreach(widget in mItemWidgets_){
                widget.setVisible(visible);
            }
        }

        function shutdown(){
            foreach(widget in mItemWidgets_){
                widget.shutdown();
            }
            mItemWidgets_.clear();
            mWidgetTimeouts_.clear();
        }

        function clearAllWidgets(){
            foreach(widget in mItemWidgets_){
                widget.shutdown();
            }
            mItemWidgets_.clear();
            mWidgetTimeouts_.clear();
        }
    };

    function setup(data){
        mExplorationScreenWidgetType_ = array(ExplorationScreenWidgetType.MAX);

        mLogicInterface_ = data.logic;
        mExplorationBus_ = ScreenBus();

        mLogicInterface_.setGuiObject(this);

        mWindow_ = _gui.createWindow("ExplorationScreen");
        mWindow_.setSize(_window.getWidth(), _window.getHeight());
        mWindow_.setVisualsEnabled(false);
        mWindow_.setSkinPack("WindowSkinNoBorder");
        mWindow_.setBreadthFirst(true);

        local screenshotMode = ::Base.isProfileActive(GameProfile.SCREENSHOT_MODE);

        local layoutLine = _gui.createLayoutLine();

        //World map display
        mWorldMapDisplay_ = WorldMapDisplay(mWindow_);

        local mobileInterface = (::Base.getTargetInterface() == TargetInterface.MOBILE);

        local statsWidget = ::GuiWidgets.PlayerBasicStatsWidget();
        statsWidget.setup(mWindow_);
        statsWidget.setPosition(Vec2(0, 0));
        statsWidget.setPlayerStats(::Base.mPlayerStats);
        mExplorationStatsContainer_ = statsWidget;

        //mExplorationStatsContainer_ = ExplorationStatsContainer(mWindow_, mExplorationBus_);
        if(mobileInterface){
            //mExplorationStatsContainer_.setPosition(Vec2(0, 0));
            //mExplorationStatsContainer_.addToLayout(layoutLine);
        }else{
            //mExplorationStatsContainer_.setPosition(Vec2(0, 0));
            //mExplorationStatsContainer_.setSize(400, 140);
        }
        //mExplorationScreenWidgetType_[ExplorationScreenWidgetType.STATS_CONTAINER] = mExplorationStatsContainer_;
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.STATS_CONTAINER] = statsWidget;

        //mExplorationItemsContainer_ = ExplorationItemsContainer(mWindow_, mExplorationBus_);
        //mExplorationItemsContainer_.addToLayout(layoutLine);

        //mExplorationEnemiesContainer_ = ExplorationEnemiesContainer(mWindow_, mExplorationBus_);
        //mExplorationMovesContainer_ = ExplorationMovesContainer(mWindow_, mExplorationBus_);
        if(mobileInterface){
            //mExplorationMovesContainer_.addToLayout(layoutLine);
        }else{
            //mExplorationMovesContainer_.setPosition(Vec2(0, 0));
            //mExplorationMovesContainer_.setSize(400, 100);
        }
        //mExplorationScreenWidgetType_[ExplorationScreenWidgetType.MOVES_CONTAINER] = mExplorationMovesContainer_;
        mWorldMapDisplay_.addToLayout(layoutLine);
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.MINIMAP] = mWorldMapDisplay_;

        mExplorationPlayerActionsContainer_ = ExplorationPlayerActionsContainer(mWindow_, this, mobileInterface);

        local layoutSize = _window.getSize();
        layoutLine.setHardMaxSize(layoutSize);
        layoutLine.setSize(layoutSize);
        layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.layout();
        mLayoutLine_ = layoutLine;

        mWorldMapDisplay_.notifyResize();

        //mExplorationStatsContainer_.sizeLayout(mWorldMapDisplay_.getMapViewerSize());

        local insets = _window.getScreenSafeAreaInsets();
        mWorldMapDisplay_.positionWorldMapDisplay(Vec2(mWorldMapDisplay_.getMapViewerPosition().x, insets.top + statsWidget.getSize().y));
        //mExplorationStatsContainer_.getSize().y
        //mExplorationMovesContainer_.sizeForButtons();

        mScreenInputCheckList_ = [
            //mExplorationStatsContainer_//,
            //mExplorationMovesContainer_
        ];

        local mobile = (::Base.getTargetInterface() == TargetInterface.MOBILE);
        if(mobile){

            mPauseButton = ::IconButton(mWindow_, "pauseIcon");
            mPauseButton.setSize(Vec2(85, 85));
            mPauseButton.setButtonVisualsEnabled(false);
            mPauseButton.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z);
            mPauseButton.attachListenerForEvent(function(widget, action){
                ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
                ::Base.mExplorationLogic.setGamePaused(true);
            }, _GUI_ACTION_PRESSED, this);
            mScreenInputCheckList_.append(mPauseButton);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.PAUSE_BUTTON] = mPauseButton;

            mPlayerTapButton = mWindow_.createButton();
            local playerSizeButton = Vec2(100, 100);
            mPlayerTapButton.setSize(playerSizeButton);
            mPlayerTapButton.setPosition(_window.getWidth() / 2 - playerSizeButton.x / 2, _window.getHeight() / 2 - playerSizeButton.y / 2);
            mPlayerTapButton.setKeyboardNavigable(false);
            mPlayerTapButton.setVisualsEnabled(false);
            //mPlayerTapButton.setPosition(_window.getWidth() / 2 - mPlayerTapButton.getSize().x/2, mCameraButton.getPosition().y - mPlayerTapButton.getSize().y - 20);
            //Swipe attack input is now tracked directly via updateSwipeTracking_() in update()
            mScreenInputCheckList_.append(mPlayerTapButton);

            //Create spinning compass panel for swipe attack feedback
            mSwipeCompassPanel_ = mWindow_.createPanel();
            mSwipeCompassPanel_.setDatablock(_hlms.getDatablock("guiExplorationCompass"));
            mSwipeCompassPanel_.setSize(Vec2(120, 120));
            mSwipeCompassPanel_.setVisible(false);
            mSwipeCompassPanel_.setClickable(false);
            mSwipeCompassPanel_.setZOrder(WIDGET_SAFE_FOR_BILLBOARD_Z - 1);

            mPlayerDirectJoystick_ = ::PlayerDirectJoystick(mWindow_);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.DIRECTION_JOYSTICK] = mPlayerDirectJoystick_;

            //Player direct, swipe attack and zoom buttons are created
            //BEFORE the camera button so they have higher priority in
            //first-match-wins dispatch.

            //Swipe attack button covers the same area as mPlayerTapButton
            //(centred on screen). On mobile this replaces the legacy mouse-
            //polling path in updateSwipeTracking_.
            mSwipeAttackButton_ = MultiTouchButton(
                Vec2(_window.getWidth() / 2 - 50, _window.getHeight() / 2 - 50),
                Vec2(100, 100)
            );
            mSwipeAttackButton_.setOnPressed(function(fingerId, pos){
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                if(world == null) return;
                if(!world.requestSwipingAttackForFinger(fingerId)) return;
                //Record start position in pixel space.
                mSwipeTapStartPos_ = Vec2(pos.x * ::canvasSize.x, pos.y * ::canvasSize.y);
                mSwipeTapEndPos_ = mSwipeTapStartPos_.copy();
                mSwipeTapActive_ = true;
                mSwipeHoldTimer_ = 0;
                mSwipeCompassRotation_ = 0.0;
                mSwipeCompassTargetOpacity_ = 0.0;
            }.bindenv(this));
            mSwipeAttackButton_.setOnMoved(function(fingerId, pos){
                if(!mSwipeTapActive_) return;
                mSwipeTapEndPos_ = Vec2(pos.x * ::canvasSize.x, pos.y * ::canvasSize.y);
            }.bindenv(this));
            mSwipeAttackButton_.setOnReleased(function(fingerId){
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                if(world != null){
                    world.releaseStateForFinger(fingerId);
                }
                if(mSwipeTapActive_){
                    mSwipeTapActive_ = false;
                    mSwipeCompassTargetOpacity_ = 0.0;
                    onSwipeAttackExecute_();
                }
            }.bindenv(this));

            mPlayerDirectButton = MultiTouchButton(Vec2(0, 0), Vec2(100, 100));
            mPlayerDirectButton.setOnPressed(function(fingerId, pos){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.requestDirectingPlayerForFinger(fingerId);
                }
            }.bindenv(this));
            mPlayerDirectButton.setOnReleased(function(fingerId){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.releaseStateForFinger(fingerId);
                }
            }.bindenv(this));
            mPlayerDirectButton.setVisible(false);

            mZoomModifierButton = MultiTouchButton(Vec2(0, 0), Vec2(100, 100));
            local zoomButtonPos = mWorldMapDisplay_.getPosition();
            zoomButtonPos.y += mWorldMapDisplay_.getMapViewerPosition().y + mWorldMapDisplay_.getMapViewerSize().y;
            zoomButtonPos.x += mWorldMapDisplay_.getSize().x - 50;
            mZoomModifierButton.setPosition(zoomButtonPos);
            mZoomModifierButton.setSize(Vec2(50, _window.getHeight() - zoomButtonPos.y - insets.bottom));
            mZoomModifierButton.setOnPressed(function(fingerId, pos){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.requestCameraZoomingForFinger(fingerId);
                    mZoomLines_.setRecentTouchInteraction();
                }
            }.bindenv(this));
            mZoomModifierButton.setOnReleased(function(fingerId){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.releaseStateForFinger(fingerId);
                }
            }.bindenv(this));

            //Camera button is created last so it has lowest dispatch priority.
            //Touches in player direct or zoom regions are claimed first.
            mCameraButton = MultiTouchButton(Vec2(0, 0), Vec2(100, 100));
            mCameraButton.setOnPressed(function(fingerId, pos){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.requestOrientingCameraWithMovementForFinger(fingerId);
                }
            }.bindenv(this));
            mCameraButton.setOnReleased(function(fingerId){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.releaseStateForFinger(fingerId);
                }
            }.bindenv(this));
            mCameraButton.setOnTapped(function(fingerId, pos){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                if(currentWorld != null){
                    currentWorld.notifyDoubleTapCheck();
                }
            }.bindenv(this));
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.CAMERA_BUTTON] = mCameraButton;

            local zoomWidth = mZoomModifierButton.getSize().x;
            mCameraButton.setPosition(Vec2(0, _window.getHeight() - zoomWidth - insets.bottom));
            mCameraButton.setSize(Vec2(_window.getWidth() - zoomWidth, zoomWidth));

            if(screenshotMode){

                mPauseButton.setVisible(false);
                mCameraButton.setVisible(false);
                mZoomModifierButton.setVisible(false);
                mPlayerDirectButton.setVisible(false);
            }
        }

        mZoomLines_ = ExplorationScreenZoomLines(mWindow_);
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.ZOOM_SLIDER] = mZoomLines_;
        if(mobile){
            mZoomLines_.setSize(mZoomModifierButton.getSize());
            mZoomLines_.setPosition(mZoomModifierButton.getPosition());
        }else{
            mZoomLines_.setSize(Vec2(50, ::drawable.y));
            mZoomLines_.setPosition(Vec2(::drawable.x - 50, 30));
        }

        mExplorationBus_.registerCallback(busCallback, this);

        mTooltipManager_ = TooltipManager();

        createInputBlockerOverlay();

        mWorldStatsScreen_ = WorldStatsScreen(mWindow_);
        checkWorldStatsVisible();

        mDiscoverLevelUpScreen_ = DiscoverLevelUpScreen(mWindow_);
        mDiscoverLevelUpScreen_.setup();

        if(screenshotMode){
            mExplorationStatsContainer_.setVisible(false);
            //mExplorationMovesContainer_.setVisible(false);
        }

        mExplorationStatsContainer_.setPosition(Vec2(0, insets.top));

        mScreenInputCheckList_.append(mWorldMapDisplay_.mMapViewerWindow_);

        mInventoryWidget_ = ::GuiWidgets.GameplayInventoryWidget(mWindow_, Vec2(100, 100));
        mInventoryWidget_.setPosition(Vec2(0, statsWidget.getPosition().y + statsWidget.getSize().y));
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.INVENTORY_INDICATOR] = mInventoryWidget_;

        //Found items manager - positioned to the right of the inventory widget
        mFoundItemIconsManager_ = FoundItemIconsManager(mWindow_);
        local inventoryWidgetPos = mInventoryWidget_.getPosition();
        mFoundItemIconsManager_.setBasePosition(inventoryWidgetPos + Vec2(0, mInventoryWidget_.getSize().y + 20));

        _event.subscribe(Event.ACTIONS_CHANGED, receiveActionsChanged, this);
        _event.subscribe(Event.WORLD_PREPARATION_STATE_CHANGE, receivePreparationStateChange, this);
        _event.subscribe(Event.REGION_DISCOVERED_POPUP_FINISHED, receiveRegionDiscoveredPopupFinished, this);
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        _event.subscribe(Event.EXPLORATION_SCREEN_HIDE_WIDGETS_FINISHED, receiveExplorationHideWidgetsFinished, this);
        _event.subscribe(Event.ITEM_GIVEN, receiveItemGiven, this);
        _event.subscribe(Event.SYSTEM_SETTINGS_CHANGED, receiveSystemSettingsChanged, this);
        _event.subscribe(Event.SCREEN_CHANGED, receiveScreenChanged, this);
        ::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);

        mAnimator_ = ExplorationScreenAnimator();
        mCompassAnimator_ = ExplorationScreenCompassAnimator(mWindow_, Vec2(400, 300));
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.COMPASS] = mCompassAnimator_;
        //mAnimator_.animateToInventoryPercentage(0.5);
        if(mobile){
            local widgetPos = mInventoryWidget_.getPosition();
            widgetPos.x += 80;

            local pauseButtonPos = widgetPos.copy();
            pauseButtonPos.x += 20;
            pauseButtonPos.y += 5;
            mPauseButton.setPosition(pauseButtonPos);

            //Camera button covers entire gameplay area below the UI,
            //excluding the zoom strip on the right edge.
            local cameraTop = mZoomModifierButton.getPosition().y;
            local cameraBottom = _window.getHeight();
            mCameraButton.setPosition(Vec2(0, cameraTop));
            mCameraButton.setSize(Vec2(mZoomModifierButton.getPosition().x, cameraBottom - cameraTop));

            mPlayerDirectButton.setSize(Vec2(100, 100));
            mPlayerDirectButton.setPosition(Vec2(mZoomModifierButton.getPosition().x - 100, mCompassAnimator_.getPosition().y - 100));
            mPlayerDirectButton.setVisible(true);

            local directSize = mPlayerDirectButton.getSize();
            mPlayerDirectJoystick_.setSize(directSize + directSize * 0.5);
            repositionJoystick_();

            local zoomLinesSize = mZoomLines_.getSize();
            zoomLinesSize.y = mCompassAnimator_.getPosition().y - mZoomLines_.getPosition().y;
            mZoomLines_.setSize(zoomLinesSize);
            mZoomModifierButton.setPosition(mZoomLines_.getPosition());
            mZoomModifierButton.setSize(mZoomLines_.getSize());

            mMobileActionInfo_ = ExplorationScreenMobileActionInfo(mWindow_);
        }

        {
            local inv = ::Base.mPlayerStats.mInventory_;
            local free = inv.getNumSlotsFree();
            local fullSize = inv.getInventorySize();
            setInventoryCount_(fullSize - free, fullSize);
        }

        if(mobile){
            //mWieldActiveButton.setPosition(Vec2(0, mExplorationStatsContainer_.getSize().y + insets.top + 200));
            //local newPos = mWieldActiveButton.getPosition();
            //newPos.y += mWieldActiveButton.getSize().y;
            local newPos = mPlayerDirectButton.getPosition().copy();
            //newPos.y -= 200;
            newPos.x = 0;
            mDiscoverLevelUpScreen_.setPosition(newPos);
        }

        if(screenshotMode){
            mCompassAnimator_.setVisible(false);
            mZoomLines_.setVisible(false);
            mInventoryWidget_.setVisible(false);
            mPlayerDirectJoystick_.setVisible(false);
            if(mMobileActionInfo_ != null){
                mMobileActionInfo_.setVisible(false);
            }
        }

        //TOOD NOTE Workaround! This isn't how the paradigm should fit together
        //Screen shouldn't dictate what the logic does other than let it know of events happening.
        ::Base.mExplorationLogic.resetExploration_();
    }

    function setScreenWidgetVisible(widgetType, visible){
        local widget = mExplorationScreenWidgetType_[widgetType];
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            visible = false;
        }
        if(widget != null){
            widget.setVisible(visible);
        }
    }

    function receiveInventoryChangedEvent(id, data){
        local count = 0;
        foreach(i in data){
            if(i != null) count++;
        }
        setInventoryCount_(count, data.len());
    }

    function receiveExplorationHideWidgetsFinished(id, data){
        setAllWidgetsVisible(true);
    }

    function setInventoryCount_(count, size){
        mAnimator_.animateToInventoryPercentage(count.tofloat() / size.tofloat());
        mInventoryWidget_.setInventoryCount(count, size);
    }

    function receiveRegionDiscoveredPopupFinished(id, data){
        //setTopInfoVisible(true);
        mTargetTopInfoOpacity_ = 1.0;
    }

    function receivePreparationStateChange(id, data){
        if(data.began){
            ::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);
        }else{
            assert(data.ended);
            ::ScreenManager.transitionToScreen(null, null, 1);
        }
    }

    function receiveActionsChanged(id, data){
        local allEmpty = true;
        foreach(i in data){
            if(i.populated()){
                allEmpty = false;
                break;
            }
        }
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            //mPlayerTapButton.setVisible(!allEmpty);
            mMobileActionInfo_.actionsChanged(data, allEmpty);
        }
        mPlayerTapButtonActive = !allEmpty;
    }

    function receiveSystemSettingsChanged(id, data){
        if(data.setting == SystemSetting.JOYSTICK_LEFT_SIDE){
            repositionJoystick_();
        }
    }

    function repositionJoystick_(){
        if(mPlayerDirectJoystick_ == null || mPlayerDirectButton == null){
            return;
        }
        local directSize = mPlayerDirectButton.getSize();
        local joystickPos = mPlayerDirectButton.getPosition() - directSize * 0.25;
        if(::SystemSettings.getSetting(SystemSetting.JOYSTICK_LEFT_SIDE)){
            joystickPos.x = 0;
        }
        mPlayerDirectJoystick_.setPosition(joystickPos);
    }

    function receiveItemGiven(id, data){
        //data is the item that was given
        local itemDef = data;
        notifyItemFound(itemDef);
    }

    function receiveScreenChanged(id, data){
        mFoundItemIconsManager_.clearAllWidgets();
    }

    function update(){
        mLogicInterface_.tickUpdate();
        //mExplorationMovesContainer_.update();
        //mExplorationStatsContainer_.update();
        mWorldMapDisplay_.update();
        mDiscoverLevelUpScreen_.update();

        mTooltipManager_.update();

        mAnimator_.update();
        mCompassAnimator_.update();
        mZoomLines_.update();
        mFoundItemIconsManager_.update();

        //Update swipe tracking: check if mouse button is held and track movement
        updateSwipeTracking_();
        updateSwipeCompassPanelVisibility_();

        updateTopInfoVisibility();

        if(mPlayerDirectJoystick_ != null){
            mPlayerDirectJoystick_.update();
        }
        if(mMobileActionInfo_ != null){
            mMobileActionInfo_.update();
        }

        //Defer the player death check until the end of the frame.
        if(mPlayerDied_ == 1){
            mPlayerDied_++;

            local worldType = WorldTypes.PLAYER_DEATH;
            local worldInstance = ::Base.mExplorationLogic.createWorldInstance(worldType, {});
            ::Base.mExplorationLogic.pushWorld(worldInstance);

            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.COMPASS].setVisible(false);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.ZOOM_SLIDER].setVisible(false);
            if(mExplorationScreenWidgetType_[ExplorationScreenWidgetType.DIRECTION_JOYSTICK]){
                mExplorationScreenWidgetType_[ExplorationScreenWidgetType.DIRECTION_JOYSTICK].setVisible(false);
            }
        }
    }

    function getMoneyCounterWindowPos(){
        return mExplorationStatsContainer_.getMoneyCounter();
    }
    function getEXPCounterWindowPos(){
        return mExplorationStatsContainer_.getEXPCounter();
    }
    function getGameplayWindowPosition(){
        return mWorldMapDisplay_.getPosition();
    }

    function createInputBlockerOverlay(){
        mInputBlockerWindow_ = _gui.createWindow("InputBlocker");
        mInputBlockerWindow_.setSize(_window.getWidth(), _window.getHeight());
        mInputBlockerWindow_.setZOrder(41);
        mInputBlockerWindow_.setVisualsEnabled(false);
        mInputBlockerWindow_.setVisible(false);
    }

    function checkWorldStatsVisible(){
        if(::Base.isProfileActive(GameProfile.DISPLAY_WORLD_STATS)){
            mWorldStatsScreen_.setVisible(true);
        }
    }

    function checkIntersect_(x, y, widget){
        local start = widget.getPosition();
        local end = widget.getSize();
        return (x >= start.x && y >= start.y && x < end.x+start.x && y < end.y+start.y);
    }
    function checkPlayerInputPosition(x, y){
        local start = mWorldMapDisplay_.getPosition();
        local end = mWorldMapDisplay_.getSize();
        if(x >= start.x && y >= start.y && x < end.x+start.x && y < end.y+start.y){
            foreach(i in mScreenInputCheckList_){
                if(checkIntersect_(x, y, i)) return null;
            }
            if(mPlayerTapButtonActive && mPlayerTapButton != null){
                if(checkIntersect_(x, y, mPlayerTapButton)) return null;
            }

            return Vec2((x-start.x) / end.x, (y-start.y) / end.y);
        }
        return null;
    }

    function updateSwipeTracking_(){
        //On mobile, swipe attack input is handled by the MultiTouchButton
        //(mSwipeAttackButton_) to avoid racing the camera orientation button.
        if(::Base.getTargetInterface() == TargetInterface.MOBILE){
            //Still need to advance the hold timer and trigger repeats.
            if(mSwipeTapActive_){
                mSwipeHoldTimer_++;
                if(mSwipeHoldTimer_ >= SWIPE_HOLD_THRESHOLD){
                    mSwipeCompassTargetOpacity_ = 1.0;
                    local holdTime = mSwipeHoldTimer_ - SWIPE_HOLD_THRESHOLD;
                    if(holdTime % SWIPE_HOLD_REPEAT_INTERVAL == 0){
                        onSwipeAttackExecute_();
                    }
                }else{
                    mSwipeCompassTargetOpacity_ = 0.0;
                }
                mSwipeCompassPanel_.setPosition(mSwipeTapEndPos_ - mSwipeCompassPanel_.getSize() / 2);
                mSwipeCompassRotation_ += 0.01;
                mSwipeCompassPanel_.setOrientation(mSwipeCompassRotation_);
            }
            return;
        }
        //Check if player tap button area is being pressed (swipe attacks always available)
        local currentMousePos = Vec2(_input.getMouseX(), _input.getMouseY());

        //Start swipe tracking if not already active and within button bounds
        if(!mSwipeTapActive_){
            local buttonPos = mPlayerTapButton.getPosition();
            local buttonSize = mPlayerTapButton.getSize();

            if(currentMousePos.x >= buttonPos.x && currentMousePos.y >= buttonPos.y &&
               currentMousePos.x < buttonPos.x + buttonSize.x && currentMousePos.y < buttonPos.y + buttonSize.y){

                if(_input.getMouseButton(_MB_LEFT)){
                    //Skip if the world has no room for a swiping attack state.
                    local world = ::Base.mExplorationLogic.mCurrentWorld_;
                    if(world != null && !world.mMouseContext_.isEmpty()){
                        //Still allow if the swiping attack is compatible with active states.
                        if(!world.requestSwipingAttackForFinger("swipe")) return;
                    }else if(world != null){
                        world.requestSwipingAttackForFinger("swipe");
                    }else{
                        return;
                    }

                    mSwipeTapStartPos_ = currentMousePos.copy();
                    mSwipeTapEndPos_ = mSwipeTapStartPos_.copy();
                    mSwipeTapActive_ = true;
                    mSwipeHoldTimer_ = 0;
                    mSwipeCompassRotation_ = 0.0;
                    mSwipeCompassTargetOpacity_ = 0.0;
                }
            }
        }

        //Update swipe end position while holding down
        if(mSwipeTapActive_){
            mSwipeTapEndPos_ = currentMousePos.copy();
            mSwipeHoldTimer_++;

            //Show compass panel only after threshold is passed
            if(mSwipeHoldTimer_ >= SWIPE_HOLD_THRESHOLD){
                mSwipeCompassTargetOpacity_ = 1.0;
                local holdTime = mSwipeHoldTimer_ - SWIPE_HOLD_THRESHOLD;
                if(holdTime % SWIPE_HOLD_REPEAT_INTERVAL == 0){
                    onSwipeAttackExecute_();
                }
            }else{
                mSwipeCompassTargetOpacity_ = 0.0;
            }

            //Update compass panel position and rotation
            mSwipeCompassPanel_.setPosition(mSwipeTapEndPos_ - mSwipeCompassPanel_.getSize() / 2);
            mSwipeCompassRotation_ += 0.01; //Rotate by 0.01 radians per frame
            mSwipeCompassPanel_.setOrientation(mSwipeCompassRotation_);

            //Check if mouse button is released (no longer pressed)
            if(!_input.getMouseButton(_MB_LEFT)){
                mSwipeTapActive_ = false;
                mSwipeCompassTargetOpacity_ = 0.0;
                //Release the swipe finger state.
                local world = ::Base.mExplorationLogic.mCurrentWorld_;
                if(world != null){
                    world.releaseStateForFinger("swipe");
                }
                onSwipeAttackExecute_();
            }
        }
    }

    function onSwipeAttackExecute_(){
        //Compute swipe direction from start to end position
        if(mSwipeTapStartPos_ == null || mSwipeTapEndPos_ == null) return;

        local swipeDelta = mSwipeTapEndPos_ - mSwipeTapStartPos_;
        if(swipeDelta.length() < 10.0) return; //Minimum swipe distance threshold

        //Normalise the swipe delta
        swipeDelta.normalise();

        //Convert screen-space swipe direction to world-space direction via camera orientation
        local world = ::Base.mExplorationLogic.mCurrentWorld_;
        if(world == null) return;

        //Get camera forward and right vectors based on camera orientation
        //mRotation_.x is horizontal rotation (around Y axis)
        //Camera is positioned at offset (cos(rot.x), 0, sin(rot.x)) from target
        //So forward direction towards target is opposite: (-cos(rot.x), 0, -sin(rot.x))
        //Right vector is perpendicular in XZ plane
        local cameraRot = world.mRotation_;

        local cameraForward = Vec3(-cos(cameraRot.x), 0, -sin(cameraRot.x));
        local cameraRight = Vec3(-sin(cameraRot.x), 0, cos(cameraRot.x));

        //Combine swipe direction with camera vectors: x-axis = right, y-axis = forward (screen Y is inverted)
        local worldAttackDir = (cameraRight * swipeDelta.x) + (cameraForward * swipeDelta.y);
        worldAttackDir.normalise();

        print(worldAttackDir)
        worldAttackDir.y = 0; //Keep attack direction horizontal

        //Resolve enemies in swipe direction and apply attack
        world.performDirectionalAttack(worldAttackDir);
    }

    function updateSwipeCompassPanelVisibility_(){
        //Animate the compass panel opacity towards the target
        mSwipeCompassCurrentOpacity_ = ::accelerationClampCoordinate_(mSwipeCompassCurrentOpacity_, mSwipeCompassTargetOpacity_, 0.1);

        //Update panel visibility and opacity
        if(mSwipeCompassCurrentOpacity_ > 0.0){
            mSwipeCompassPanel_.setVisible(true);
            mSwipeCompassPanel_.setColour(ColourValue(1, 1, 1, mSwipeCompassCurrentOpacity_));
        }else{
            mSwipeCompassPanel_.setVisible(false);
        }
    }

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        //mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
    }

    function notifyItemFound(itemDef){
        //Add the item to the found items display
        if(itemDef != null && itemDef.getMesh() != null){
            mFoundItemIconsManager_.addItem(itemDef);
        }
    }

    function notifyHighlightEnemy(enemy){
        if(enemy != null){
            local string = ::Enemies[enemy].getName();
            mTooltipManager_.setTooltip(string);
        }
        mTooltipManager_.setVisible(enemy != null);
    }

    function notifyEnemyEncounter(idx, enemy, position=null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        mExplorationEnemiesContainer_.setObjectForIndex(enemy, idx, screenPos);
    }

    //Block input while a flag movement is in progress, to prevent buttons being pressed when they shouldn't be.
    function notifyBlockInput(block){
        mInputBlockerWindow_.setVisible(block);
    }

    function notifyFoundItemLifetime(idx, lifetime){
        //mExplorationItemsContainer_.setLifetimeForIndex(idx, lifetime);
    }
    function notifyQueuedEnemyLifetime(idx, lifetime){
        mExplorationEnemiesContainer_.setLifetimeForIndex(idx, lifetime);
    }

    function shutdown(){
        _event.unsubscribe(Event.WORLD_PREPARATION_STATE_CHANGE, receivePreparationStateChange, this);
        _event.unsubscribe(Event.ACTIONS_CHANGED, receiveActionsChanged, this);
        _event.unsubscribe(Event.REGION_DISCOVERED_POPUP_FINISHED, receiveRegionDiscoveredPopupFinished, this);
        _event.unsubscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        _event.unsubscribe(Event.EXPLORATION_SCREEN_HIDE_WIDGETS_FINISHED, receiveExplorationHideWidgetsFinished, this);
        _event.unsubscribe(Event.ITEM_GIVEN, receiveItemGiven, this);
        _event.unsubscribe(Event.SYSTEM_SETTINGS_CHANGED, receiveSystemSettingsChanged, this);
        _event.unsubscribe(Event.SCREEN_CHANGED, receiveScreenChanged, this);
        mLogicInterface_.shutdown();
        //mLogicInterface_.notifyLeaveExplorationScreen();
        //mExplorationStatsContainer_.shutdown();
        mWorldMapDisplay_.shutdown();
        mDiscoverLevelUpScreen_.shutdown();
        mExplorationPlayerActionsContainer_.shutdown();
        mInventoryWidget_.shutdown();
        mFoundItemIconsManager_.shutdown();
        mCompassAnimator_.shutdown();
        mExplorationStatsContainer_.shutdown();
        if(mPlayerDirectJoystick_){
            mPlayerDirectJoystick_.shutdown();
        }
        //Shutdown MultiTouchButton instances.
        if(mCameraButton != null && (mCameraButton instanceof MultiTouchButton)){
            mCameraButton.shutdown();
        }
        if(mZoomModifierButton != null && (mZoomModifierButton instanceof MultiTouchButton)){
            mZoomModifierButton.shutdown();
        }
        if(mPlayerDirectButton != null && (mPlayerDirectButton instanceof MultiTouchButton)){
            mPlayerDirectButton.shutdown();
        }
        if(mSwipeAttackButton_ != null && (mSwipeAttackButton_ instanceof MultiTouchButton)){
            mSwipeAttackButton_.shutdown();
        }
        base.shutdown();
    }

    function busCallback(event, data){
        if(event == ExplorationBusEvents.TRIGGER_ITEM){

            if(data.type == FoundObjectType.ITEM){
                if(data.item.getType() == ItemType.MONEY){
                    //Just claim money immediately, no screen switching.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);

                }else{
                    //Switch to the item info screen.
                    //data.mode <- ItemInfoMode.KEEP_SCRAP_EXPLORATION;
                    //TODO temp, just scrap the item.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);
                }
                local worldPos = ::EffectManager.getWorldPositionForWindowPos(data.buttonCentre);
                local endPos = mMoneyCounter_.getPositionWindowPos();
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 10, "numCoins": 2, "start": worldPos, "end": endPos, "money": 100}));
            }
            else if(data.type == FoundObjectType.PLACE){
                //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.PLACE_INFO_SCREEN, data));
            }else{
                assert(false);
            }

        }
        else if(event == ExplorationBusEvents.TRIGGER_ENCOUNTER){
            mLogicInterface_.triggerCombatEarly();
        }
    }

    function notifyPlayerMove(moveId){
        //return mExplorationMovesContainer_.notifyPlayerMove(moveId);
        return true;
    }

    function showPopup(popupData){
        if(popupData.id == Popup.REGION_DISCOVERED){
            local yPos = 50;
            if(::Base.getTargetInterface() == TargetInterface.MOBILE){
                /*
                local statsContainer = mExplorationScreenWidgetType_[ExplorationScreenWidgetType.STATS_CONTAINER];
                yPos = statsContainer.getPosition().y + statsContainer.getSize().y - 10;
                */
                local insets = _window.getScreenSafeAreaInsets();
                yPos = insets.top + 20;

                //setTopInfoVisible(false);
                mTargetTopInfoOpacity_ = 0.25;
            }
            popupData.data.pos <- Vec2(0, yPos);
        }

        ::PopupManager.displayPopup(popupData);
    }

    function updateTopInfoVisibility(){
        local old = mTopInfoAnim_;
        mTopInfoAnim_ = ::accelerationClampCoordinate_(mTopInfoAnim_, mTargetTopInfoOpacity_, 0.1);
        if(old != mTopInfoAnim_){
            setTopInfoOpacity(mTopInfoAnim_);
        }
    }

    function setTopInfoVisible(visible){
        local vis = visible;
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            vis = false;
        }
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.MINIMAP].setVisible(vis);
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.STATS_CONTAINER].setVisible(vis);
        if(mExplorationScreenWidgetType_[ExplorationScreenWidgetType.PAUSE_BUTTON]){
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.PAUSE_BUTTON].setVisible(vis);
        }
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.INVENTORY_INDICATOR].setVisible(vis);
        //mExplorationStatsContainer_.setVisible(vis);
        //mWorldMapDisplay_.setVisible(vis);
    }

    function setAllWidgetsVisible(visible){
        setTopInfoVisible(visible);

        local vis = visible;
        if(::Base.isProfileActive(GameProfile.SCREENSHOT_MODE)){
            vis = false;
        }

        mCompassAnimator_.setVisible(vis);
        if(mPlayerDirectJoystick_){
            mPlayerDirectJoystick_.setVisible(vis);
        }
        mZoomLines_.setVisible(vis);
    }

    function setTopInfoOpacity(opacity){
        local target = ColourValue(1, 1, 1, opacity);

        if(mExplorationScreenWidgetType_[ExplorationScreenWidgetType.PAUSE_BUTTON]){
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.PAUSE_BUTTON].setColour(target);
        }
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.INVENTORY_INDICATOR].setColour(target);
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.STATS_CONTAINER].setColour(target);
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.MINIMAP].setColour(target);
    }

    function notifyGatewayEnd(explorationStats){
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_END_SCREEN, explorationStats), null, 1);
    }

    function notifyPlayerDeath(){
        mPlayerDied_++;

        //mTargetTopInfoOpacity_ = 0.0;
        setAllWidgetsVisible(false);

        _window.grabCursor(false);
    }

    function notifyPlayerTarget(target){
        _event.transmit(Event.PLAYER_TARGET_CHANGE, target);
    }
};

_doFile("script://ExplorationScreenCompassAnimator.nut");
_doFile("script://ExplorationWorldMapDisplay.nut");
_doFile("script://ExplorationMovesContainer.nut");
_doFile("script://ExplorationEndScreen.nut");
_doFile("script://ExplorationPlayerDeathScreen.nut");
_doFile("script://ExplorationStatsContainer.nut");
_doFile("script://ExplorationTooltipManager.nut");
_doFile("script://ExplorationPlayerActionsContainer.nut");