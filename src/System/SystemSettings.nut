::SystemSettings <- {

    mSettings_ = null

    function setup(){
        mSettings_ = array(SystemSetting.MAX, null);

        setupDefaultValues();
    }

    function setupDefaultValues(){
        mSettings_[SystemSetting.INVERT_CAMERA_CONTROLLER] = false;
        mSettings_[SystemSetting.JOYSTICK_LEFT_SIDE] = false;
    }

    function setSettingsValue(setting, value){
        mSettings_[setting] = value;

        local eventData = {
            "setting": setting,
            "value": value
        };
        _event.transmit(Event.SYSTEM_SETTINGS_CHANGED, eventData);
    }

    function getSetting(setting){
        return mSettings_[setting];
    }

}

::SystemSettings.setup();