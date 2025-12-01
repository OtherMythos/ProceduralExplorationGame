#pragma once

namespace ProceduralExplorationGameCore{

#ifdef TARGET_IPHONE
    void initialiseHapticFeedbackSystem();
    void triggerLightHapticFeedback();
    void triggerMediumHapticFeedback();
    void triggerHeavyHapticFeedback();
    void triggerSelectionHapticFeedback();
    void triggerNotificationHapticFeedback(int notificationType);
#else
    //No-op stubs for non-iOS platforms
    inline void initialiseHapticFeedbackSystem(){}
    inline void triggerLightHapticFeedback(){}
    inline void triggerMediumHapticFeedback(){}
    inline void triggerHeavyHapticFeedback(){}
    inline void triggerSelectionHapticFeedback(){}
    inline void triggerNotificationHapticFeedback(int notificationType){}
#endif

}
