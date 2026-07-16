#import "QOLPreferences.h"

NSString *const QOLDefaultsSuite = @"com.omeriadon.QOL";
NSString *const QOLSettingsDidChangeNotification = @"com.omeriadon.QOL.settingsDidChange";
NSString *const QOLMusicPulsePreviewNotification = @"com.omeriadon.QOL.previewMusicPulse";

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

NSString *QOLString(NSString *key, NSString *fallback) {
    id value = [QOLDefaults() objectForKey:key];
    return [value isKindOfClass:NSString.class] ? value : fallback;
}

NSData *QOLData(NSString *key) {
    id value = [QOLDefaults() objectForKey:key];
    return [value isKindOfClass:NSData.class] ? value : nil;
}

NSColor *QOLColor(NSString *key, NSColor *fallback) {
    NSArray<NSString *> *components = [QOLString(key, @"") componentsSeparatedByString:@","];
    if (components.count != 3) return fallback;
    return [NSColor colorWithSRGBRed:components[0].doubleValue
                               green:components[1].doubleValue
                                blue:components[2].doubleValue
                               alpha:1.0];
}
