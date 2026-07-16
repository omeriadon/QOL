#import "QOLPreferences.h"

NSString *const QOLDefaultsSuite = @"com.omeriadon.QOL";
NSString *const QOLSettingsDidChangeNotification = @"com.omeriadon.QOL.settingsDidChange";
NSString *const QOLMusicPulsePreviewNotification = @"com.omeriadon.QOL.previewMusicPulse";
NSString *const QOLCommandLensPreviewNotification = @"com.omeriadon.QOL.previewCommandLens";

NSUserDefaults *QOLDefaults(void) {
    return [[NSUserDefaults alloc] initWithSuiteName:QOLDefaultsSuite];
}

BOOL QOLBool(NSString *key, BOOL fallback) {
    id value = [QOLDefaults() objectForKey:key];
    return value ? [value boolValue] : fallback;
}

double QOLDouble(NSString *key, double fallback) {
    id value = [QOLDefaults() objectForKey:key];
    return value ? [value doubleValue] : fallback;
}

NSInteger QOLInteger(NSString *key, NSInteger fallback) {
    id value = [QOLDefaults() objectForKey:key];
    return value ? [value integerValue] : fallback;
}
