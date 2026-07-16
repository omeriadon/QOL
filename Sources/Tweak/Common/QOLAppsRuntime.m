@import AppKit;

#import "QOLCursorController.h"
#import "QOLSoftScrollEdgesController.h"

@interface QOLAppsRuntime : NSObject
@end

@implementation QOLAppsRuntime

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier ?: @"";
        NSString *packageType = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundlePackageType"] ?: @"";
        BOOL finder = [bundleIdentifier isEqualToString:@"com.apple.finder"];
        if ((!finder && ![packageType isEqualToString:@"APPL"]) ||
            [bundleIdentifier isEqualToString:@"com.omeriadon.QOLSettings"] ||
            NSApp == nil) {
            return;
        }

        [QOLCursorController install];
        [QOLSoftScrollEdgesController install];
    });
}

@end
