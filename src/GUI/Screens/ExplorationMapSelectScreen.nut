
::ScreenManager.Screens[Screen.EXPLORATION_MAP_SELECT_SCREEN] = class extends ::Screen{

    mMapPanel_ = null;

    mMapPosition_ = null;
    mMapAcceleration_ = null;
    mMapPanelWidth_ = 4000;
    mMapPanelHeight_ = 4000;
    mMapPanelWidthChecked_ = null;
    mMapPanelHeightChecked_ = null;

    mPrevMouseX_ = null;
    mPrevMouseY_ = null;

    function recreate(){
        mMapPosition_ = Vec2();
        mMapAcceleration_ = Vec2(0.0, 0.0);

        mWindow_ = _gui.createWindow("ExplorationMapSelectScreen");
        mWindow_.setSize(::drawable);
        mWindow_.setClipBorders(0, 0, 0, 0);
        local MARGIN = 10;

        local insets = _window.getScreenSafeAreaInsets();

        mMapPanel_ = mWindow_.createPanel();
        mMapPanel_.setSize(mMapPanelWidth_, mMapPanelHeight_);
        mMapPanel_.setDatablock("explorationMapPanel");
        mMapPanelWidthChecked_ = mMapPanelWidth_ - ::drawable.x;
        mMapPanelHeightChecked_ = mMapPanelHeight_ - ::drawable.y;

        local closeButton = mWindow_.createButton();
        closeButton.setText("Back");
        closeButton.setPosition(MARGIN, MARGIN + insets.top);
        closeButton.attachListenerForEvent(function(widget, action){
            ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
        }, _GUI_ACTION_PRESSED, this);

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
            local viableSaves = ::Base.mSaveManager.findViableSaves();
            local saveSlot = 0;
            local save = ::Base.mSaveManager.readSaveAtPath("user://" + viableSaves[saveSlot].tostring());
            ::Base.mPlayerStats.setSaveData(save, saveSlot);

            ::ScreenManager.transitionToScreen(null, null, 0);
            ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
            ::ScreenManager.transitionToScreen(::ScreenManager.ScreenData(Screen.EXPLORATION_SCREEN, {"logic": ::Base.mExplorationLogic}));
        }, _GUI_ACTION_PRESSED, this);

        updateMapPosition_(mMapPosition_);
    }

    function update(){
        local delta = processMouseDelta();
        if(delta != null){
            mMapAcceleration_ = -delta;
        }
        mMapAcceleration_.x = accelerationClampCoordinate_(mMapAcceleration_.x);
        mMapAcceleration_.y = accelerationClampCoordinate_(mMapAcceleration_.y);

        updateMapPosition_(mMapPosition_ + mMapAcceleration_);
    }

    function updateMapPosition_(pos){
        if(pos.x < 0) pos.x = 0;
        if(pos.y < 0) pos.y = 0;
        if(pos.x >= mMapPanelWidthChecked_) pos.x = mMapPanelWidthChecked_;
        if(pos.y >= mMapPanelHeightChecked_) pos.y = mMapPanelHeightChecked_;

        mMapPosition_ = pos;
        //print(mMapPosition_);
        mMapPanel_.setPosition(-mMapPosition_);
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

};
