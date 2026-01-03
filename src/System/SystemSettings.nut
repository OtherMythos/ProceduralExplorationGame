::SystemSettings <- {

    mSettings_ = null
    mSettingsFilePath_ = "user://settings.json"

    function setup(){
        mSettings_ = array(SystemSetting.MAX, null);

        setupDefaultValues();
        readSettingsFromFile();
    }

    function setupDefaultValues(){
        mSettings_[SystemSetting.INVERT_CAMERA_CONTROLLER] = false;
        mSettings_[SystemSetting.JOYSTICK_LEFT_SIDE] = false;
    }

    function transmitSettingChangedEvent_(setting){
        local eventData = {
            "setting": setting,
            "value": mSettings_[setting]
        };
        _event.transmit(Event.SYSTEM_SETTINGS_CHANGED, eventData);
    }

    function readSettingsFromFile(){
        if(!_system.exists(mSettingsFilePath_)){
            return;
        }

        try{
            local settingsTable = _system.readJSONAsTable(mSettingsFilePath_);

            for(local i = 0; i < SystemSetting.MAX; i++){
                local key = ::SystemSettingString[i];
                if(key in settingsTable){
                    mSettings_[i] = settingsTable[key];
                }else{
                    //Missing key, use default
                }
            }

            //Transmit event for each setting
            for(local i = 0; i < SystemSetting.MAX; i++){
                transmitSettingChangedEvent_(i);
            }
        }catch(e){
            printf("Failed to read settings file: %s", e);
        }
    }

    function writeSettingsToFile(){
        print("Attempting to write system settings to file.");
        try{
            local settingsTable = {};
            for(local i = 0; i < SystemSetting.MAX; i++){
                local key = ::SystemSettingString[i];
                settingsTable[key] <- mSettings_[i];
            }

            _system.writeJsonAsFile(mSettingsFilePath_, settingsTable);
        }catch(e){
            printf("Failed to write settings file: %s", e);
        }
    }

    function setSettingsValue(setting, value){
        mSettings_[setting] = value;
        writeSettingsToFile();

        transmitSettingChangedEvent_(setting);
    }

    function getSetting(setting){
        return mSettings_[setting];
    }

}

::SystemSettings.setup();