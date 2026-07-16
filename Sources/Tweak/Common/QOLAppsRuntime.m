@import AppKit;

#import "QOLAppCapsuleController.h"
#import "QOLCommandLensController.h"

@interface QOLAppsRuntime : NSObject
@end

@implementation QOLAppsRuntime

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier ?: @"";
        NSString *packageType = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundlePackageType"] ?: @"";
        if (![packageType isEqualToString:@"APPL"] ||
            [bundleIdentifier isEqualToString:@"com.omeriadon.QOLSettings"] ||
            NSApp == nil) {
            return;
        }

        [QOLCommandLensController install];
        [QOLAppCapsuleController install];
    });
}

@end

