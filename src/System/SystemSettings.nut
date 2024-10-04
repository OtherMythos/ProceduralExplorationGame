::SystemSettings <- {

    mSettings_ = null

    function setup(){
        mSettings_ = array(SystemSetting.MAX, null);

        setupDefaultValues();
    }

    function setupDefaultValues(){
        mSettings_[SystemSetting.INVERT_CAMERA_CONTROLLER] = false;
    }

    function setSettingsValue(setting, value){
        mSettings_[setting] = value;

        _event.transmit(Event.SYSTEM_SETTINGS_CHANGED, setting);
    }

    function getSetting(setting){
        return mSettings_[setting];
    }

}

::SystemSettings.setup();