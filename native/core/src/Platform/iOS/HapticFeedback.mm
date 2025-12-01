#ifdef TARGET_IPHONE

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

namespace ProceduralExplorationGameCore{

    //Initialise feedback generators once to avoid first-call delay
    static void initialiseHapticFeedbackGenerators(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(__builtin_available(iOS 10.0, *)){
                UIImpactFeedbackGenerator *light = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                [light prepare];

                UIImpactFeedbackGenerator *medium = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                [medium prepare];

                UIImpactFeedbackGenerator *heavy = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                [heavy prepare];

                UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
                [selection prepare];

                UINotificationFeedbackGenerator *notification = [[UINotificationFeedbackGenerator alloc] init];
                [notification prepare];
            }
        });
    }

    void initialiseHapticFeedbackSystem(){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            initialiseHapticFeedbackGenerators();
        });
    }

    //Provide haptic feedback using UIImpactFeedbackGenerator
    //Supports light, medium, and heavy impact feedback
    void triggerLightHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
                [generator prepare];
                [generator impactOccurred];
            });
        }
    }

    void triggerMediumHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                [generator prepare];
                [generator impactOccurred];
            });
        }
    }

    void triggerHeavyHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
                [generator prepare];
                [generator impactOccurred];
            });
        }
    }

    //Provide selection feedback for UI interactions
    void triggerSelectionHapticFeedback(){
        if(__builtin_available(iOS 10.0, *)){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UISelectionFeedbackGenerator *generator = [[UISelectionFeedbackGenerator alloc] init];
                [generator prepare];
                [generator selectionChanged];
            });
        }
    }

    //Provide notification feedback
    void triggerNotificationHapticFeedback(int notificationType){
        if(__builtin_available(iOS 10.0, *)){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
                [generator prepare];
                UINotificationFeedbackType type = (UINotificationFeedbackType)notificationType;
                [generator notificationOccurred:type];
            });
        }
    }
}

#endif
