@import Foundation;

#import "QOLMusicPulseController.h"

@interface QOLDockRuntime : NSObject
@end

@implementation QOLDockRuntime

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [QOLMusicPulseController install];
    });
}

@end

