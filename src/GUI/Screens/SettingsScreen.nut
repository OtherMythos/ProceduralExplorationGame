::ScreenManager.Screens[Screen.SETTINGS_SCREEN] = class extends ::Screen{

    mSettingsWidgets_ = null

    function setup(data){

        mSettingsWidgets_ = array(SystemSetting.MAX);

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
        mWindow_.setSkinPack("Button_midGrey");

        createScreenCloseButton();

        local layoutLine = _gui.createLayoutLine();
        local buttonList_ = [];

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText("Settings");
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        layoutLine.addCell(title);

        local invertCamera = mWindow_.createCheckbox();
        invertCamera.setText("Invert Camera");
        invertCamera.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::SystemSettings.setSettingsValue(SystemSetting.INVERT_CAMERA_CONTROLLER, widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layoutLine.addCell(invertCamera);
        buttonList_.append(invertCamera);
        mSettingsWidgets_[SystemSetting.INVERT_CAMERA_CONTROLLER] = invertCamera;

        local wireframeButton = mWindow_.createButton();
        wireframeButton.setText("Toggle wireframe");
        wireframeButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::toggleDrawWireframe();
        }, _GUI_ACTION_PRESSED);
        layoutLine.addCell(wireframeButton);
        buttonList_.append(wireframeButton);
        mSettingsWidgets_[SystemSetting.TOGGLE_WIREFRAME] = wireframeButton;

        local renderStatsButton = mWindow_.createButton();
        renderStatsButton.setText("Toggle Render Stats");
        renderStatsButton.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            _window.toggleRenderStats();
        }, _GUI_ACTION_PRESSED);
        layoutLine.addCell(renderStatsButton);
        buttonList_.append(renderStatsButton);
        mSettingsWidgets_[SystemSetting.TOGGLE_WIREFRAME] = renderStatsButton;

        local joystickSideCheckbox = mWindow_.createCheckbox();
        joystickSideCheckbox.setText("Joystick on Left Side");
        joystickSideCheckbox.attachListenerForEvent(function(widget, action){
            ::HapticManager.triggerSimpleHaptic(HapticType.LIGHT);
            ::SystemSettings.setSettingsValue(SystemSetting.JOYSTICK_LEFT_SIDE, widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layoutLine.addCell(joystickSideCheckbox);
        buttonList_.append(joystickSideCheckbox);
        mSettingsWidgets_[SystemSetting.JOYSTICK_LEFT_SIDE] = joystickSideCheckbox;

        layoutLine.setMarginForAllCells(0, 10);
        //layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(winWidth, winHeight);

        //Apply height sizing to buttons
        foreach(button in buttonList_){
            local buttonSize = button.getSize();
            button.setSize(buttonSize.x, buttonSize.y * 0.8);
        }

        //Display current world seed information
        local seedLabel = mWindow_.createLabel();
        seedLabel.setText(getWorldSeedString_());
        layoutLine.addCell(seedLabel);

        layoutLine.layout();

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
        backButton.setSkinPack("Button_blue");
        backButton.setFocus();

        local tickmarkSize = invertCamera.getTickmarkSize();
        invertCamera.setTickmarkMarginAndSize(7, 0, 40, 40);
        joystickSideCheckbox.setTickmarkMarginAndSize(7, 0, 40, 40);

        setupValuesFromSystemSettings();
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
            local text = "Seed: %i, %i, %i";
            out = format(text, mapData.seed, mapData.moistureSeed, mapData.variationSeed);
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