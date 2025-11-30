#ifdef TARGET_IPHONE

#import <UIKit/UIKit.h>

namespace ProceduralExplorationGameCore{

    //Provide haptic feedback using UIImpactFeedbackGenerator
    //Supports light, medium, and heavy impact feedback
    void triggerLightHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
            [generator impactOccurred];
        }
    }

    void triggerMediumHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [generator impactOccurred];
        }
    }

    void triggerHeavyHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
            [generator impactOccurred];
        }
    }

    //Provide selection feedback for UI interactions
    void triggerSelectionHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            UISelectionFeedbackGenerator *generator = [[UISelectionFeedbackGenerator alloc] init];
            [generator selectionChanged];
        }
    }

    //Provide notification feedback
    void triggerNotificationHapticFeedback(int notificationType){
        if(__builtin_available(iOS 10.0, *)){
            UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
            switch(notificationType){
                case 0://Success
                    [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
                    break;
                case 1://Warning
                    [generator notificationOccurred:UINotificationFeedbackTypeWarning];
                    break;
                case 2://Error
                    [generator notificationOccurred:UINotificationFeedbackTypeError];
                    break;
                default:
                    [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
                    break;
            }
        }
    }
}

#endif
