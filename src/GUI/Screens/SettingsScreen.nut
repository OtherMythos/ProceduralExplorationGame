::ScreenManager.Screens[Screen.SETTINGS_SCREEN] = class extends ::Screen{

    mSettingsWidgets_ = null

    function setup(data){

        mSettingsWidgets_ = array(SystemSetting.MAX);

        local winWidth = _window.getWidth() * 0.8;
        local winHeight = _window.getHeight() * 0.8;

        createBackgroundScreen_();

        mWindow_ = _gui.createWindow("SettingsScreen");
        mWindow_.setSize(winWidth, winHeight);
        mWindow_.setPosition(_window.getWidth() * 0.1, _window.getHeight() * 0.1);
        mWindow_.setClipBorders(10, 10, 10, 10);
        mWindow_.setBreadthFirst(true);
        mWindow_.setZOrder(61);

        local layoutLine = _gui.createLayoutLine();

        local title = mWindow_.createLabel();
        title.setDefaultFontSize(title.getDefaultFontSize() * 2);
        title.setTextHorizontalAlignment(_TEXT_ALIGN_CENTER);
        title.setGridLocation(_GRID_LOCATION_CENTER);
        title.setText("Settings");
        title.sizeToFit(mWindow_.getSizeAfterClipping().x);
        layoutLine.addCell(title);

        local backButton = mWindow_.createButton();
        backButton.setText("Back");
        backButton.attachListenerForEvent(function(widget, action){
            closeSettings();
        }, _GUI_ACTION_PRESSED, this);
        layoutLine.addCell(backButton);

        local invertCamera = mWindow_.createCheckbox();
        invertCamera.setText("Invert Camera");
        invertCamera.attachListenerForEvent(function(widget, action){
            ::SystemSettings.setSettingsValue(SystemSetting.INVERT_CAMERA_CONTROLLER, widget.getValue());
        }, _GUI_ACTION_RELEASED);
        layoutLine.addCell(invertCamera);
        mSettingsWidgets_[SystemSetting.INVERT_CAMERA_CONTROLLER] = invertCamera;

        backButton.setFocus();

        layoutLine.setMarginForAllCells(0, 20);
        //layoutLine.setGridLocationForAllCells(_GRID_LOCATION_CENTER);
        layoutLine.setSize(winWidth, winHeight);
        layoutLine.layout();


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

    function update(){
        if(_input.getButtonAction(::InputManager.menuBack, _INPUT_PRESSED)){
            if(::ScreenManager.isForefrontScreen(mLayerIdx)){
                ::ScreenManager.queueTransition(null, null, mLayerIdx);
            }
        }
    }
}