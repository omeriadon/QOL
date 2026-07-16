@import AppKit;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const QOLDefaultsSuite;
FOUNDATION_EXPORT NSString *const QOLSettingsDidChangeNotification;
FOUNDATION_EXPORT NSString *const QOLMusicPulsePreviewNotification;

FOUNDATION_EXPORT NSUserDefaults *QOLDefaults(void);
FOUNDATION_EXPORT BOOL QOLBool(NSString *key, BOOL fallback);
FOUNDATION_EXPORT double QOLDouble(NSString *key, double fallback);
FOUNDATION_EXPORT NSInteger QOLInteger(NSString *key, NSInteger fallback);
FOUNDATION_EXPORT NSString *QOLString(NSString *key, NSString *fallback);
FOUNDATION_EXPORT NSData *_Nullable QOLData(NSString *key);
FOUNDATION_EXPORT NSColor *QOLColor(NSString *key, NSColor *fallback);

NS_ASSUME_NONNULL_END
