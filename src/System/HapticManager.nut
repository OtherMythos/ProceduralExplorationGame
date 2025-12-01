enum HapticType{
    LIGHT,
    MEDIUM,
    HEAVY,
    SELECTION,
    NOTIFICATION_SUCCESS,
    NOTIFICATION_WARNING,
    NOTIFICATION_ERROR
};

::HapticManager <- {
    function initialise(){
        _gameCore.initialiseHapticFeedbackSystem();
    }

    function triggerSimpleHaptic(hapticType){
        switch(hapticType){
            case HapticType.LIGHT:
                _gameCore.triggerLightHapticFeedback();
                break;
            case HapticType.MEDIUM:
                _gameCore.triggerMediumHapticFeedback();
                break;
            case HapticType.HEAVY:
                _gameCore.triggerHeavyHapticFeedback();
                break;
            case HapticType.SELECTION:
                _gameCore.triggerSelectionHapticFeedback();
                break;
            case HapticType.NOTIFICATION_SUCCESS:
                _gameCore.triggerNotificationHapticFeedback(0);
                break;
            case HapticType.NOTIFICATION_WARNING:
                _gameCore.triggerNotificationHapticFeedback(1);
                break;
            case HapticType.NOTIFICATION_ERROR:
                _gameCore.triggerNotificationHapticFeedback(2);
                break;
            default:
                break;
        }
    }
};
