enum ExplorationBusEvents{
    TRIGGER_ITEM,
    TRIGGER_ENCOUNTER
};

enum ExplorationScreenWidgetType{
    STATS_CONTAINER,
    MOVES_CONTAINER,
    MINIMAP,
    WIELD_BUTTON,
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
    mWieldActiveButton = null;
    mZoomModifierButton = null;
    mCameraButton = null;
    mPlayerDirectButton = null;
    mPlayerDirectJoystick_ = null;
    mPlayerTapButton = null;
    mPlayerTapButtonActive = false;
    mDiscoverLevelUpScreen_ = null;
    mInventoryWidget_ = null;
    mLayoutLine_ = null;
    mZoomLines_ = null;
    mMobileActionInfo_ = null;

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
                if(currentWorld.getCurrentMouseState() != WorldMousePressContexts.ZOOMING){
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

    ExplorationScreenCompassAnimator = class{
        mTexture_ = null;
        mDatablock_ = null;

        mCompassWindow_ = null;
        mCompassPanel_ = null;
        mParentNode_ = null;
        mCompassNode_ = null;

        mRenderWorkspace_ = null;

        mDirectionNodes_ = null;

        constructor(window, size){

            mDirectionNodes_ = [];

            local texture = _graphics.createTexture("explorationCompassTexture");
            texture.setResolution((size.x * ::resolutionMult.x).tointeger(), (size.y.tointeger() * ::resolutionMult.y).tointeger());
            texture.setPixelFormat(_PFG_RGBA8_UNORM);
            texture.scheduleTransitionTo(_GPU_RESIDENCY_RESIDENT);

            mTexture_ = texture;
            mRenderWorkspace_ = _compositor.addWorkspace([texture], _camera.getCamera(), "compositor/GamplayExplorationCompassWorkspace", true);
            //mRenderWorkspace_.update();

            local blendBlock = _hlms.getBlendblock({
                "src_blend_factor": _HLMS_SBF_SOURCE_ALPHA,
                "dst_blend_factor": _HLMS_SBF_ONE_MINUS_SOURCE_ALPHA,
                "src_alpha_blend_factor": _HLMS_SBF_ONE_MINUS_DEST_ALPHA,
                "dst_alpha_blend_factor": _HLMS_SBF_ONE
            });
            local datablock = _hlms.unlit.createDatablock("gameplayExplorationCompassDatablock", blendBlock);
            datablock.setTexture(0, texture);
            //mIconBackground_.setDatablock(datablock);
            mDatablock_ = datablock;

            mCompassWindow_ = window.createWindow();
            mCompassWindow_.setClickable(false);
            mCompassWindow_.setPosition(0, ::drawable.y - 150);
            mCompassWindow_.setSize(400, 200);
            mCompassWindow_.setClipBorders(0, 0, 0, 0);
            mCompassWindow_.setVisualsEnabled(false);

            local compassPanel = mCompassWindow_.createPanel();
            //compassPanel.setPosition(0, ::drawable.y - 250);
            compassPanel.setClickable(false);
            compassPanel.setSize(400, 300);
            compassPanel.setPosition(0, -100);
            mCompassPanel_ = compassPanel;
            //mCameraButton.setPosition(compassPanel.getPosition());
            //mCameraButton.setSize(compassPanel.getSize());

            local node = _scene.getRootSceneNode().createChildSceneNode();
            local compassNode = node.createChildSceneNode();
            local item = _scene.createItem("plane");
            item.setRenderQueueGroup(74);
            compassNode.attachObject(item);
            compassNode.setOrientation(Quat(0, 0, 1, sqrt(0.1)));
            node.setPosition(0, 0, -3);
            item.setDatablock("guiExplorationCompass");
            mCompassNode_ = compassNode;
            mParentNode_ = node;
            compassPanel.setDatablock(mDatablock_);

            for(local i = 0; i < 4; i++){
                local target = node.createChildSceneNode();
                local track = mCompassNode_.createChildSceneNode();
                local dirPlane = _scene.createItem("plane");
                dirPlane.setDatablock(getDatablock_(i));
                dirPlane.setRenderQueueGroup(74);
                target.setScale(0.1, 0.1, 0.1);
                local pos = getDirection_(i);
                target.setPosition(pos);
                track.setPosition(pos);
                //target.setOrientation(Quat(PI * 0.75, ::Vec3_UNIT_X));
                //target.setPosition(0, 0, 0);
                target.attachObject(dirPlane);
                mDirectionNodes_.append([target, track]);
                //target.setScale(0.5, 0.5, 0.5);
            }
        }

        function setVisible(visible){
            mCompassWindow_.setVisible(visible);
        }

        function getDatablock_(dir){
            switch(dir){
                case 0:
                    return "guiExplorationCompassSouth";
                case 1:
                    return "guiExplorationCompassEast";
                case 2:
                    return "guiExplorationCompassNorth";
                case 3:
                    return "guiExplorationCompassWest";
                default:
                    assert(false);
            }
        }

        function getDirection_(dir){
            switch(dir){
                case 0:
                    //North
                    return Vec3(1, 0, 0);
                case 1:
                    //East
                    return Vec3(0, 1, 0);
                case 2:
                    //South
                    return Vec3(-1, 0, 0);
                case 3:
                    //East
                    return Vec3(0, -1, 0);

                default:
                    return Vec3();
            }
        }

        function shutdown(){
            _compositor.removeWorkspace(mRenderWorkspace_);
            _gui.destroy(mCompassWindow_);
            _hlms.destroyDatablock(mDatablock_);
            _graphics.destroyTexture(mTexture_);
            mCompassNode_.destroyNodeAndChildren();
            mParentNode_.destroyNodeAndChildren();

            mCompassWindow_ = null;
            mCompassPanel_ = null;
            mTexture_ = null;
            mDatablock_ = null;
            mParentNode_ = null;
            mCompassNode_ = null;
            mDirectionNodes_ = null;
        }

        function getPosition(){
            return mCompassWindow_.getPosition();
        }

        function getSize(){
            return mCompassWindow_.getSize();
        }

        function update(){
            local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
            local currentRotation = currentWorld.mRotation_.x;
            local currentYRotation = currentWorld.mRotation_.y;

            //print(currentYRotation);

            local range =
                (PI * 0.5) - (PI * 0.1);
            local animOther = (currentYRotation - (PI * 0.1)) / range;
            //print(animOther);

            local compassOrientation = Quat();
            compassOrientation *= Quat(PI / 2 + 0.20, ::Vec3_UNIT_X);
            //compassOrientation *= Quat(animCount % 0.15, ::Vec3_UNIT_X);
            //compassOrientation *= Quat(PI * 2 * ::animCount, ::Vec3_UNIT_Z);
            compassOrientation *= Quat(animOther * 0.1, ::Vec3_UNIT_X);
            //if(currentRotation < 0) currentRotation = -currentRotation;
            //print(currentRotation);
            local an = (currentRotation % (PI * 2)) / (PI * 2);
            //print(an);
            compassOrientation *= Quat(PI * 2 * (-an), ::Vec3_UNIT_Z);

            // Camera "right" axis in world space
            local cameraNode = _camera.getCamera().getParentNode();
            local cameraRight = cameraNode.getOrientation() * Vec3(1,0,0);

            // Transform into plane local space
            local planeRightLocal = compassOrientation.inverse() * cameraRight;
            planeRightLocal.normalise();

            // Now build scale vector
            // Start at (1,1,1), then add extra scale along that local axis
            // We want 1.5 instead of 1.0 → factor = 0.5
            local extra = planeRightLocal * 0.5;
            local scale = Vec3(1,1,1) + extra.abs(); // abs to keep positive scale
            //print(extra);


            //mCompassNode_.setScale(1.5, 1, 1);
            mCompassNode_.setOrientation(compassOrientation);
            //mCompassNode_.setScale(scale.x, scale.z, 1);
            mCompassNode_.setScale(1.5, 1.5, 1);

            foreach(i in mDirectionNodes_){
                i[0].setPosition(i[1].getDerivedPositionVec3());
                //i[0].lookAt(_camera.getPosition());
            }

        }
    }

    ExplorationScreenMobileActionInfo = class{

        mParent_ = null;
        mLabel_ = null;
        mAnimationPanel_ = null;
        mAnimationPanelBackground_ = null;
        mButton_ = null;

        mLottieAnimation_ = null;
        mLottieAnimationSecond_ = null;

        mDatablock_ = null;
        mBackgroundDatablock_ = null;

        mTargetAnimation_ = 0.0;
        mAnim_ = 1.0;

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

            local totalSize =  (mLabel_.getPosition() + mLabel_.getSize()) - mAnimationPanel_.getPosition();
            mButton_.setSize(totalSize);
            mButton_.setPosition(mAnimationPanel_.getPosition());
        }

        function setOpacity(opacity){
            //mLabel_.setVisible(visible);
            //mAnimationPanel_.setVisible(visible);
            //mAnimationPanelBackground_.setVisible(visible);
            mLabel_.setTextColour(ColourValue(1, 1, 1, opacity));
            mLabel_.setShadowOutline(true, ColourValue(0, 0, 0, opacity), Vec2(2, 2));

            //mDatablock_.setUseColour(true);
            //mAnimationPanel_.setColour(ColourValue(1, 1, 1, opacity));
            //TODO I wasn't able to fade in the opacity due to how the blendblocks are setup.
            mAnimationPanel_.setVisible(opacity >= 0.5);
            mAnimationPanelBackground_.setVisible(opacity >= 0.5);
            mButton_.setVisible(opacity >= 0.5);
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
            reposition_();
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
            }else if(percentage > 0.5 && percentage <= 0.8){
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
            mWindow_.setVisible(true && !::Base.isProfileActive(GameProfile.SCREENSHOT_MODE));
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
            //mWieldActiveButton = mWindow_.createButton();
            mWieldActiveButton = ::IconButton(mWindow_, "swordsIcon");
            mWieldActiveButton.setSize(Vec2(100, 100));
            mWieldActiveButton.setButtonVisualsEnabled(false);
            //mWieldActiveButton.setText("Wield");
            //mWieldActiveButton.setPosition(_window.getWidth() / 2 - mWieldActiveButton.getSize().x/2, _window.getHeight() - mWieldActiveButton.getSize().y*2);
            mWieldActiveButton.attachListenerForEvent(function(widget, action){
                ::Base.mPlayerStats.toggleWieldActive();
            }, _GUI_ACTION_PRESSED, this);
            mScreenInputCheckList_.append(mWieldActiveButton);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.WIELD_BUTTON] = mWieldActiveButton;

            mCameraButton = mWindow_.createButton();
            //mCameraButton.setText("Camera");
            //mCameraButton.setPosition(_window.getWidth() / 2 - mCameraButton.getSize().x/2 - mWieldActiveButton.getSize().x - 20, _window.getHeight() - mWieldActiveButton.getSize().y*2);
            //mCameraButton.setPosition(_window.getWidth() / 2 - mCameraButton.getSize().x/2, _window.getHeight() - mWieldActiveButton.getSize().y*2 - mCameraButton.getSize().y - 20);
            mCameraButton.attachListenerForEvent(function(widget, action){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                currentWorld.requestOrientingCamera();
            }, _GUI_ACTION_PRESSED, this);
            mCameraButton.setVisualsEnabled(false);
            mScreenInputCheckList_.append(mCameraButton);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.CAMERA_BUTTON] = mCameraButton;

            mPlayerTapButton = mWindow_.createButton();
            local playerSizeButton = Vec2(100, 100);
            mPlayerTapButton.setSize(playerSizeButton);
            mPlayerTapButton.setPosition(_window.getWidth() / 2 - playerSizeButton.x / 2, _window.getHeight() / 2 - playerSizeButton.y / 2);
            mPlayerTapButton.setKeyboardNavigable(false);
            mPlayerTapButton.setVisible(false);
            mPlayerTapButton.setVisualsEnabled(false);
            //mPlayerTapButton.setPosition(_window.getWidth() / 2 - mPlayerTapButton.getSize().x/2, mCameraButton.getPosition().y - mPlayerTapButton.getSize().y - 20);
            mPlayerTapButton.attachListenerForEvent(function(widget, action){
                //::Base.mActionManager.executeSlot(0);
            }, _GUI_ACTION_PRESSED);
            //mScreenInputCheckList_.append(mPlayerTapButton);

            mPlayerDirectJoystick_ = ::PlayerDirectJoystick(mWindow_);
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.DIRECTION_JOYSTICK] = mPlayerDirectJoystick_;

            mPlayerDirectButton = mWindow_.createButton();
            local playerSizeButton = Vec2(100, 100);
            mPlayerDirectButton.setText("Direct");
            //mPlayerDirectButton.setSize(playerSizeButton);
            //mPlayerDirectButton.setPosition(_window.getWidth() / 2 - playerSizeButton.x / 2, _window.getHeight() / 2 - playerSizeButton.y / 2);
            mPlayerDirectButton.setKeyboardNavigable(false);
            //mPlayerDirectButton.setVisualsEnabled(false);
            //mPlayerDirectButton.setPosition(_window.getWidth() / 2 - mPlayerDirectButton.getSize().x/2, mCameraButton.getPosition().y - mPlayerDirectButton.getSize().y - 20);
            mPlayerDirectButton.attachListenerForEvent(function(widget, action){
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                currentWorld.requestDirectingPlayer();
            }, _GUI_ACTION_PRESSED);
            mPlayerDirectButton.setVisible(false);

            mZoomModifierButton = mWindow_.createButton();
            mZoomModifierButton.setText("Zoom");
            mZoomModifierButton.setVisualsEnabled(false);
            local zoomButtonPos = mWorldMapDisplay_.getPosition();
            zoomButtonPos.y += mWorldMapDisplay_.getMapViewerPosition().y + mWorldMapDisplay_.getMapViewerSize().y;
            zoomButtonPos.x += mWorldMapDisplay_.getSize().x - mZoomModifierButton.getSize().x;
            mZoomModifierButton.setPosition(zoomButtonPos);
            mZoomModifierButton.setSize(mZoomModifierButton.getSize().x, _window.getHeight() - zoomButtonPos.y - insets.bottom);
            //mZoomModifierButton.setSize(40, 40);
            mZoomModifierButton.attachListenerForEvent(function(widget, action){
                //TODO clean up direct access
                local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
                currentWorld.requestCameraZooming();
                mZoomLines_.setRecentTouchInteraction();
            }, _GUI_ACTION_PRESSED, this);
            mZoomModifierButton.setSkinPack("ButtonZoom");
            mZoomModifierButton.setText("");
            mScreenInputCheckList_.append(mZoomModifierButton);

            local zoomWidth = mZoomModifierButton.getSize().x;
            mCameraButton.setPosition(0, _window.getHeight() - zoomWidth - insets.bottom);
            mCameraButton.setSize(_window.getWidth() - zoomWidth, zoomWidth);
            mCameraButton.setSkinPack("ButtonZoom");

            if(screenshotMode){
                mWieldActiveButton.setVisible(false);
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

        _event.subscribe(Event.ACTIONS_CHANGED, receiveActionsChanged, this);
        _event.subscribe(Event.WORLD_PREPARATION_STATE_CHANGE, receivePreparationStateChange, this);
        _event.subscribe(Event.REGION_DISCOVERED_POPUP_FINISHED, receiveRegionDiscoveredPopupFinished, this);
        _event.subscribe(Event.INVENTORY_CONTENTS_CHANGED, receiveInventoryChangedEvent, this);
        ::ScreenManager.transitionToScreen(Screen.WORLD_GENERATION_STATUS_SCREEN, null, 1);

        mAnimator_ = ExplorationScreenAnimator();
        mCompassAnimator_ = ExplorationScreenCompassAnimator(mWindow_, Vec2(400, 300));
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.COMPASS] = mCompassAnimator_;
        //mAnimator_.animateToInventoryPercentage(0.5);
        if(mobile){
            local widgetPos = mInventoryWidget_.getPosition();
            widgetPos.x += 100;
            mWieldActiveButton.setPosition(widgetPos);

            mCameraButton.setPosition(mCompassAnimator_.getPosition());
            mCameraButton.setSize(mCompassAnimator_.getSize());

            mPlayerDirectButton.setSize(100, 100);
            mPlayerDirectButton.setPosition(mZoomModifierButton.getPosition().x - 100, mCompassAnimator_.getPosition().y - 100);
            mPlayerDirectButton.setSkinPack("ButtonZoom");

            local directSize = mPlayerDirectButton.getSize();
            mPlayerDirectJoystick_.setSize(directSize + directSize * 0.5);
            mPlayerDirectJoystick_.setPosition(mPlayerDirectButton.getPosition() - directSize * 0.25);

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
            mPlayerTapButton.setVisible(!allEmpty);
            mMobileActionInfo_.actionsChanged(data, allEmpty);
        }
        mPlayerTapButtonActive = !allEmpty;
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

    function notifyObjectFound(foundObject, idx, position = null){
        local screenPos = position != null ? mWorldMapDisplay_.getWorldPositionInScreenSpace(position) : null;
        //mExplorationItemsContainer_.setObjectForIndex(foundObject, idx, screenPos);
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
        mLogicInterface_.shutdown();
        //mLogicInterface_.notifyLeaveExplorationScreen();
        //mExplorationStatsContainer_.shutdown();
        mWorldMapDisplay_.shutdown();
        mDiscoverLevelUpScreen_.shutdown();
        mExplorationPlayerActionsContainer_.shutdown();
        mInventoryWidget_.shutdown();
        mCompassAnimator_.shutdown();
        mExplorationStatsContainer_.shutdown();
        if(mPlayerDirectJoystick_){
            mPlayerDirectJoystick_.shutdown();
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
                    //::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.ITEM_INFO_SCREEN, data));
                    //TODO temp, just scrap the item.
                    local itemData = data.item.getData();
                    ::ItemHelper.actuateItem(data.item);
                    ::Base.mExplorationLogic.removeFoundItem(data.slotIdx);
                }
                local worldPos = ::EffectManager.getWorldPositionForWindowPos(data.buttonCentre);
                local endPos = mMoneyCounter_.getPositionWindowPos();
                ::EffectManager.displayEffect(::EffectManager.EffectData(Effect.SPREAD_COIN_EFFECT, {"cellSize": 2, "coinScale": 0.1, "numCoins": 2, "start": worldPos, "end": endPos, "money": 100}));
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
        if(mExplorationScreenWidgetType_[ExplorationScreenWidgetType.WIELD_BUTTON]){
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.WIELD_BUTTON].setVisible(vis);
        }
        mExplorationScreenWidgetType_[ExplorationScreenWidgetType.INVENTORY_INDICATOR].setVisible(vis);
        //mExplorationStatsContainer_.setVisible(vis);
        //mWorldMapDisplay_.setVisible(vis);
    }

    function setTopInfoOpacity(opacity){
        local target = ColourValue(1, 1, 1, opacity);

        if(mExplorationScreenWidgetType_[ExplorationScreenWidgetType.WIELD_BUTTON]){
            mExplorationScreenWidgetType_[ExplorationScreenWidgetType.WIELD_BUTTON].setColour(target);
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

        mTargetTopInfoOpacity_ = 0.0;

        _window.grabCursor(false);
    }

    function notifyPlayerTarget(target){
        _event.transmit(Event.PLAYER_TARGET_CHANGE, target);
    }
};

_doFile("script://ExplorationWorldMapDisplay.nut");
_doFile("script://ExplorationMovesContainer.nut");
_doFile("script://ExplorationEndScreen.nut");
_doFile("script://ExplorationPlayerDeathScreen.nut");
_doFile("script://ExplorationStatsContainer.nut");
_doFile("script://ExplorationTooltipManager.nut");
_doFile("script://ExplorationPlayerActionsContainer.nut");