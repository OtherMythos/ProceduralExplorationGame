::ScreenManager.Screens[Screen.SETTINGS_SCREEN] = class extends ::Screen{

    mSettingsWidgets_ = null
    mLayoutLine_ = null
    mButtonList_ = null
    mHiddenWidgets_ = null
    mTitleRevealCount_ = 0
    mWidgetsRevealed_ = false

    function setup(data){

        mSettingsWidgets_ = array(SystemSetting.MAX);
        mButtonList_ = [];
        mHiddenWidgets_ = {};

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        createBackgroundScreen_();
        createBackgroundCloseButton_();

        mWindow_ = _gui.createWindow("SettingsScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setBreadthFirst(true);
        mWindow_.setZOrder(61);
        _gameCore.setWidgetCustomParameter(mWindow_, 0, HLMS_UNLIT_WINDOW_BACKGROUND_PIXELS);
        mWindow_.setSkinPack("Button_midGrey");

        createScreenCloseButton();

        mLayoutLine_ = _gui.createLayoutLine();
        local afterClip = mWindow_.getSizeAfterClipping();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText("Settings");
        title.sizeToFit(afterClip.x);
        mLayoutLine_.addCell(title);

        local invertCamera = mWindow_.createCheckbox();
        invertCamera.setText("Invert Camera");
        invertCamera.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::SystemSettings.setSettingsValue(SystemSetting.INVERT_CAMERA_CONTROLLER, widget.getValue());
        }, _GUI_ACTION_RELEASED);
        invertCamera.setTextHorizontalAlignment(_TEXT_ALIGN_LEFT);
        mLayoutLine_.addCell(invertCamera);
        mButtonList_.append(invertCamera);
        mSettingsWidgets_[SystemSetting.INVERT_CAMERA_CONTROLLER] = invertCamera;

        local joystickSideCheckbox = mWindow_.createCheckbox();
        joystickSideCheckbox.setText("Joystick on Left Side");
        joystickSideCheckbox.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::SystemSettings.setSettingsValue(SystemSetting.JOYSTICK_LEFT_SIDE, widget.getValue());
        }, _GUI_ACTION_RELEASED);
        joystickSideCheckbox.setTextHorizontalAlignment(_TEXT_ALIGN_LEFT);
        mLayoutLine_.addCell(joystickSideCheckbox);
        mButtonList_.append(joystickSideCheckbox);
        mSettingsWidgets_[SystemSetting.JOYSTICK_LEFT_SIDE] = joystickSideCheckbox;

        mLayoutLine_.setMarginForAllCells(0, 10);
        mLayoutLine_.setSize(afterClip.x, afterClip.y);

        mLayoutLine_.layout();
        //Apply height sizing to buttons
        foreach(button in mButtonList_){
            local buttonSize = button.getSize();
            button.setSize(afterClip.x, buttonSize.y * 0.8);
        }
        local maxHeight = ::evenOutButtonsForHeight(mButtonList_);


        local backButton = mWindow_.createButton();
        backButton.setDefaultFontSize(backButton.getDefaultFontSize() * 1.5);
        backButton.setText("Back");
        backButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            closeSettings();
        }, _GUI_ACTION_PRESSED, this);
        local winSizeClipping = mWindow_.getSizeAfterClipping();
        backButton.setPosition(0, winSizeClipping.y - backButton.getSize().y);
        backButton.setSize(winSizeClipping.x, backButton.getSize().y);
        backButton.setDatablock("internal/ButtonSkin");
        _gameCore.setWidgetCustomParameter(backButton, 0, HLMS_UNLIT_OUTLINE_GLEAM | HLMS_UNLIT_SIMPLE_DIFFUSE);
        backButton.setSkinPack("Button_blue");
        backButton.setFocus();

        local tickmarkSize = invertCamera.getTickmarkSize();
        invertCamera.setTickmarkMarginAndSize(7, 0, 40, 40);
        joystickSideCheckbox.setTickmarkMarginAndSize(7, 0, 40, 40);

        //Create invisible reveal button by the title
        local revealButton = mWindow_.createButton();
        revealButton.attachListenerForEvent(function(widget, action){
            print("Settings title pressed");
            mTitleRevealCount_++;
            if(mTitleRevealCount_ >= 3){
                revealHiddenWidgets_();
            }
        }, _GUI_ACTION_PRESSED, this);
        revealButton.setSize(title.getSize());
        revealButton.setPosition(title.getPosition());
        revealButton.setVisualsEnabled(false);

        setupValuesFromSystemSettings();
    }

    function revealHiddenWidgets_(){
        if(mWidgetsRevealed_){
            return;
        }
        mWidgetsRevealed_ = true;

        //Create wireframe button
        local wireframeButton = mWindow_.createButton();
        wireframeButton.setText("Toggle wireframe");
        wireframeButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::toggleDrawWireframe();
        }, _GUI_ACTION_PRESSED);
        mLayoutLine_.addCell(wireframeButton);
        mButtonList_.append(wireframeButton);
        mHiddenWidgets_["wireframe"] <- wireframeButton;

        //Create render stats button
        local renderStatsButton = mWindow_.createButton();
        renderStatsButton.setText("Toggle Render Stats");
        renderStatsButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            _window.toggleRenderStats();
        }, _GUI_ACTION_PRESSED);
        mLayoutLine_.addCell(renderStatsButton);
        mButtonList_.append(renderStatsButton);
        mHiddenWidgets_["renderStats"] <- renderStatsButton;

        //Create seed label
        local seedLabel = mWindow_.createLabel();
        seedLabel.setText(getWorldSeedString_());
        mLayoutLine_.addCell(seedLabel);
        mHiddenWidgets_["seedLabel"] <- seedLabel;

        //Create debug console button
        local debugConsoleButton = mWindow_.createButton();
        debugConsoleButton.setText("Toggle Debug Console");
        debugConsoleButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::DebugConsole.toggleActive();
        }, _GUI_ACTION_PRESSED);
        mLayoutLine_.addCell(debugConsoleButton);
        mButtonList_.append(debugConsoleButton);
        mHiddenWidgets_["debugConsole"] <- debugConsoleButton;

        //Apply height sizing to new buttons
        foreach(button in [wireframeButton, renderStatsButton, debugConsoleButton]){
            local buttonSize = button.getSize();
            button.setSize(buttonSize.x, buttonSize.y * 0.8);
        }

        //Re-layout
        mLayoutLine_.layout();
    }

    function closeSettings(){
        if(mLayerIdx == 0){
            ::ScreenManager.backupScreen(mLayerIdx);
        }else{
            ::ScreenManager.transitionToScreen(null, null, mLayerIdx);
        }
    }

    function setupValuesFromSystemSettings(){
        for(local i = 0; i < SystemSetting.MAX; i++){
            local setting = ::SystemSettings.getSetting(i);
            if(setting == null) continue;
            mSettingsWidgets_[i].setValue(setting);
        }
    }

    function getWorldSeedString_(){
        local currentWorld = ::Base.mExplorationLogic.mCurrentWorld_;
        local out = " ";
        if(currentWorld == null){
            return out;
        }
        local worldType = currentWorld.getWorldType();
        if(worldType == WorldTypes.PROCEDURAL_EXPLORATION_WORLD){
            local mapData = currentWorld.getMapData();
            out = "Seed: " + ::SeedHelper.toHex(mapData.seed);
        }
        return out;
    }

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isForefrontScreen(mLayerIdx)){
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            }
        }
    }
}