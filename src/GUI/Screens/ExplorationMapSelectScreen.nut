
::ScreenManager.Screens[Screen.EXPLORATION_MAP_SELECT_SCREEN] = class extends ::Screen{

    mBusId_ = null;

    mMapPanel_ = null;
    mCompositor_ = null;

    mMapPosition_ = null;
    mMapAcceleration_ = null;
    /*
    mMapPanelWidth_ = 4000;
    mMapPanelHeight_ = 4000;
    */

    /*
    mDrawableWidthChecked_ = null;
    mDrawableHeightChecked_ = null;
    mMapPanelWidthChecked_ = null;
    mMapPanelHeightChecked_ = null;
    */

    mPrevMouseX_ = null;
    mPrevMouseY_ = null;

    mMapInfoPanel_ = null;
    mMapInfoData_ = null;

    mMapFullScreen_ = false;
    mMapMainScreenPanel_ = null;
    mMapAnimCount_ = 1.0;
    mMapAnimFinished_ = true;
    mMapPanelCoords_ = null;

    mCloseButton_ = null;
    mCloseButtonStart_ = null;
    mExploreButtonStart_ = null;
    mExploreButton_ = null;

    mCurrentTargetRegion_ = 0;

    MapInfoPanel = class{

        mWindow_ = null;
        mLabel_ = null;

        constructor(parent){
            mWindow_ = parent.createWindow();
            mWindow_.setSize(100, 100);
            mWindow_.setDatablock("simpleGrey");
            mWindow_.setVisualsEnabled(false);

            mLabel_ = mWindow_.createLabel();
            mLabel_.setTextHorizontalAlignment(_TEXT_ALIGN_RIGHT);
            mLabel_.setShadowOutline(true, ColourValue(0.05, 0.05, 0.05, 1.0), Vec2(1, 1));
        }

        function updateForData(data){
            local text = "";
            if(data != null){
                text += data.name + "\n";
                text += format("unlock amount: %i\n", data.unlockAmount);
            }
            mLabel_.setText(text);

            local newSize = mWindow_.calculateChildrenSize();
            mWindow_.setSize(newSize);
            reposition();
        }

        function reposition(){
            local insets = _window.getScreenSafeAreaInsets();
            local MARGIN = 10;
            mWindow_.setPosition(Vec2(::drawable.x - mWindow_.getSize().x - MARGIN, MARGIN + insets.top));
        }

        function setPosition(pos){
            mWindow_.setPosition(pos);
        }

    }

    function setup(data){
        base.setup(data);

        if(data != null){
            mBusId_ = data.registerCallback(busCallback, this);
        }

        _event.subscribe(Event.OVERWORLD_SELECTED_REGION_CHANGED, receiveSelectionChangeEvent, this);
    }

    function recreate(){
        mMapPosition_ = Vec2();
        mMapAcceleration_ = Vec2(0.0, 0.0);

        mWindow_ = _gui.createWindow("ExplorationMapSelectScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setClipBorders(0, 0, 0, 0);
        mWindow_.setVisualsEnabled(false);
        local MARGIN = 10;

        local insets = _window.getScreenSafeAreaInsets();

        /*
        mMapPanel_ = mWindow_.createPanel();
        mMapPanel_.setSize(mMapPanelWidth_, mMapPanelHeight_);
        mMapPanel_.setDatablock("explorationMapPanel");
        mDrawableWidthChecked_ = ::drawable.x / 2;
        mDrawableHeightChecked_ = ::drawable.y / 2;
        mMapPanelWidthChecked_ = mMapPanelWidth_ - mDrawableWidthChecked_;
        mMapPanelHeightChecked_ = mMapPanelHeight_ - mDrawableHeightChecked_;
        */

        _gameCore.setCameraForNode("renderMainGameplayNode", "compositor/camera0");

        //local datablock = ::CompositorManager.getDatablockForCompositor(mCompositor_);
        //::overworldCompositor <- mCompositor_;

        /*
        mMapPanel_ = mWindow_.createPanel();
        mMapPanel_.setSize(::drawable);
        local datablock = ::OverworldLogic.getCompositorDatablock();
        mMapPanel_.setDatablock(datablock);
        */

        mMapMainScreenPanel_ = mWindow_.createPanel();
        mMapMainScreenPanel_.setVisible(false);
        local datablock = ::OverworldLogic.getCompositorDatablock();
        mMapMainScreenPanel_.setDatablock(datablock);

        local closeButton = mWindow_.createButton();
        closeButton.setText("Back");
        closeButton.setPosition(MARGIN, MARGIN + insets.top);
        closeButton.attachListenerForEvent(function(widget, action){
            processCloseScreen_();
        }, _GUI_ACTION_PRESSED, this);
        mCloseButtonStart_ = closeButton.getPosition();
        mCloseButton_ = closeButton;

        local playIconButton = ::IconButtonComplex(mWindow_, {
            "icon": "swordsIcon",
            "iconSize": Vec2(80, 80),
            "iconPosition": Vec2(50, 0),
            "label": "Explore",
            "labelPosition": Vec2(130, 0),
            "labelSizeModifier": 2
        });
        local playSize = Vec2(340, 80);
        playIconButton.setSize(playSize);
        playIconButton.setPosition(Vec2(MARGIN / 2 + ::drawable.x / 2 - playSize.x / 2, ::drawable.y - MARGIN - playSize.y - insets.bottom));
        playIconButton.attachListenerForEvent(function(widget, action){
            processExplorationActionButtonPressed_();
        }, _GUI_ACTION_PRESSED, this);
        mExploreButtonStart_ = playIconButton.getPosition();
        mExploreButton_ = playIconButton;

        mMapInfoPanel_ = MapInfoPanel(mWindow_);
        //mMapInfoPanel_.setPosition(Vec2(::drawable.x - 100 - MARGIN, MARGIN + insets.top));
        mMapInfoPanel_.reposition();

        updateMapPosition_(mMapPosition_);

        //::OverworldLogic.setRenderableSize(::drawable * ::resolutionMult);
        ::OverworldLogic.requestSetup();
        //::OverworldLogic.requestState(OverworldStates.ZOOMED_IN);
    }

    function shutdown(){
        if(mBusId_ != null){
            mScreenData_.data.deregisterCallback(mBusId_);
        }
        mScreenData_.data.notifyEvent(GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_FINISHED, null);
        base.shutdown();
        ::OverworldLogic.requestShutdown();
        ::Base.applyCompositorModifications()

        _event.unsubscribe(Event.OVERWORLD_SELECTED_REGION_CHANGED, receiveSelectionChangeEvent, this);
    }

    function receiveSelectionChangeEvent(id, data){
        print("Overworld selected region changed");

        mCurrentTargetRegion_ = data.id;
        if(data.data == null){
            mCurrentTargetRegion_ = null;
        }

        refreshWidgets_();
    }

    function processCloseScreen_(){
        if(!mMapAnimFinished_) return;

        //::OverworldLogic.requestState(OverworldStates.ZOOMED_OUT);
        mScreenData_.data.notifyEvent(GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_STARTED, null);
    }

    function processExplorationActionButtonPressed_(){
        if(!mMapAnimFinished_) return;

        local discoveryCount = ::Base.mPlayerStats.getRegionIdDiscovery(mCurrentTargetRegion_);
        if(discoveryCount == 0){
            unlockRegionForId_(mCurrentTargetRegion_);
        }else{
            beginExplorationForRegion_(mCurrentTargetRegion_);
        }

    }

    function refreshWidgets_(){
        if(mCurrentTargetRegion_ == null){
            mExploreButton_.setText("Invalid");
            return;
        }

        local discoveryCount = ::Base.mPlayerStats.getRegionIdDiscovery(mCurrentTargetRegion_);

        if(discoveryCount == 0){
            mExploreButton_.setText("Unlock");
        }else{
            mExploreButton_.setText("Explore");
        }

        //mMapInfoPanel_.updateForData(data.data);
    }

    function unlockRegionForId_(regionId){
        ::OverworldLogic.unlockRegion(regionId);

        refreshWidgets_();
    }

    function beginExplorationForRegion_(regionId){
        ::ScreenManager.transitionToScreen(null, null, 0);
        ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
        ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
    }

    function getExplorationStartEndValues(){
        local d = null;

        local panelStart = mMapPanelCoords_;
        if(panelStart == null){
            panelStart = {
                "pos": Vec2(100, 100),
                "size": Vec2(100, 100)
            };
        }

        if(mMapFullScreen_){
            d = {
                "startPos": panelStart.pos,
                "startSize": panelStart.size,
                "endPos": ::Vec2_ZERO,
                "endSize": ::drawable,
            };
        }else{
            d = {
                "endPos": panelStart.pos,
                "endSize": panelStart.size,
                "startPos": ::Vec2_ZERO,
                "startSize": ::drawable,
            };
        }

        return d;
    }

    function updateExplorationMapAnimation(){
        if(mMapAnimCount_ == 1.0){
            if(mMapAnimFinished_ == false){
                if(!mMapFullScreen_){
                    mScreenData_.data.notifyEvent(GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_FINISHED, null);
                    ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
                }else{
                    mScreenData_.data.notifyEvent(GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_FINISHED, null);
                }
            }

            mMapAnimFinished_ = true;
            if(mMapFullScreen_){
                //local mapPanel = mTabWindows_[0].getMapPanel();
                ::OverworldLogic.setRenderableSize(::Vec2_ZERO, ::drawable);
            }
            return;
        }
        mMapAnimCount_ = ::accelerationClampCoordinate_(mMapAnimCount_, 1.0, 0.02);

        {
            local animStart = mMapFullScreen_ ? 0.0 : 0.2;
            local animEnd = mMapFullScreen_ ? 0.8 : 1.0;

            local v = getExplorationStartEndValues();
            local startPos = v.startPos;
            local startSize = v.startSize;

            local endPos = v.endPos;
            local endSize = v.endSize;

            local animPos = ::calculateSimpleAnimationInRange(startPos, endPos, mMapAnimCount_, animStart, animEnd);
            local animSize = ::calculateSimpleAnimationInRange(startSize, endSize, mMapAnimCount_, animStart, animEnd);

            mMapMainScreenPanel_.setPosition(animPos);
            mMapMainScreenPanel_.setSize(animSize);

            ::OverworldLogic.setRenderableSize(animPos, animSize);
        }

        //Back button
        {
            local animStart = mMapFullScreen_ ? 0.8 : 0.0;
            local animEnd = mMapFullScreen_ ? 1.0 : 0.2;

            local offscreenPos = mCloseButtonStart_.copy();
            offscreenPos.y = -100;
            local startPos = mMapFullScreen_ ? offscreenPos : mCloseButtonStart_;
            local endPos = mMapFullScreen_ ? mCloseButtonStart_ : offscreenPos;
            local animPos = ::calculateSimpleAnimationInRange(startPos, endPos, mMapAnimCount_, animStart, animEnd);

            mCloseButton_.setPosition(animPos);
        }

        //Explore button
        {
            local animStart = mMapFullScreen_ ? 0.8 : 0.0;
            local animEnd = mMapFullScreen_ ? 1.0 : 0.2;

            local offscreenPos = mExploreButtonStart_.copy();
            offscreenPos.y += 200;
            local startPos = mMapFullScreen_ ? offscreenPos : mExploreButtonStart_;
            local endPos = mMapFullScreen_ ? mExploreButtonStart_ : offscreenPos;
            local animPos = ::calculateSimpleAnimationInRange(startPos, endPos, mMapAnimCount_, animStart, animEnd);

            mExploreButton_.setPosition(animPos);
        }
    }

    function update(){
        local delta = processMouseDelta();
        if(delta != null){
            mMapAcceleration_ = -delta;
        }
        mMapAcceleration_.x = accelerationClampCoordinate_(mMapAcceleration_.x, 0.0, 0.2);
        mMapAcceleration_.y = accelerationClampCoordinate_(mMapAcceleration_.y, 0.0, 0.2);

        //print(mMapAcceleration_.x);

        updateExplorationMapAnimation();

        //::OverworldLogic.update();
        ::OverworldLogic.applyCameraDelta(mMapAcceleration_);
        ::OverworldLogic.applyZoomDelta(_input.getMouseWheelValue());
        //updateMapPosition_(mMapPosition_ + mMapAcceleration_);
    }

    function updateMapPosition_(pos){
        //if(pos.x < -mDrawableWidthChecked_) pos.x = -mDrawableWidthChecked_;
        //if(pos.y < -mDrawableHeightChecked_) pos.y = -mDrawableHeightChecked_;
        //if(pos.x >= mMapPanelWidthChecked_) pos.x = mMapPanelWidthChecked_;
        //if(pos.y >= mMapPanelHeightChecked_) pos.y = mMapPanelHeightChecked_;

        mMapPosition_ = pos;
        //mMapInfoData_ = {
        //    "x": ((mMapPosition_.x + mDrawableWidthChecked_) / 100).tointeger(),
        //    "y": ((mMapPosition_.y + mDrawableHeightChecked_) / 100).tointeger()
        //};
        //mMapInfoPanel_.setData(mMapInfoData_);

        //print(mMapPosition_);
        //mMapPanel_.setPosition(-mMapPosition_);
    }

    function processMouseDelta(alterPrev=true){
        local retVal = null;
        if(_input.getMouseButton(_MB_LEFT)){

            local mouseX = _input.getMouseX();
            local mouseY = _input.getMouseY();
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                local deltaX = mouseX - mPrevMouseX_;
                local deltaY = mouseY - mPrevMouseY_;
                //printf("delta x: %f y: %f", deltaX, deltaY);
                retVal = Vec2(deltaX, deltaY);
                //processCameraMove(deltaX*-0.2, deltaY*-0.2);
            }
            if(alterPrev || (mPrevMouseX_ == null && mPrevMouseY_ == null)){
                mPrevMouseX_ = mouseX;
                mPrevMouseY_ = mouseY;
            }
        }else{
            //Wait for the first move to happen.
            if(mPrevMouseX_ != null && mPrevMouseY_ != null){
                mPrevMouseX_ = null;
                mPrevMouseY_ = null;
            }
        }
        return retVal;
    }

    function setExplorationMapFullscreen(fullscreen){
        local changed = (mMapFullScreen_ != fullscreen);
        mMapFullScreen_ = fullscreen;

        if(changed){

            //local mapPanel = mTabWindows_[0].getMapPanel();
            if(mMapFullScreen_){
                //mapPanel.setVisible(false);
                mMapMainScreenPanel_.setVisible(true);
                mMapMainScreenPanel_.setClickable(false);
                //mMapMainScreenPanel_.setPosition(0, 0);
                //mMapMainScreenPanel_.setSize(::drawable);

                //local datablock = ::OverworldLogic.getCompositorDatablock();
                //mMapMainScreenPanel_.setDatablock(datablock);
            }else{
                //mapPanel.setVisible(true);
                //mMapMainScreenPanel_.setVisible(false);
            }
            mMapAnimCount_ = 0.0;
            mMapAnimFinished_ = false;

        }
    }

    function busCallback(event, data){
        //if(mHasShutdown_) return;

        if(event == GameplayComplexMenuBusEvents.SHOW_EXPLORATION_MAP_STARTED){
            mMapPanelCoords_ = data;
            setExplorationMapFullscreen(true);
        }
        else if(event == GameplayComplexMenuBusEvents.CLOSE_EXPLORATION_STARTED){
            setExplorationMapFullscreen(false);
        }
    }

};
