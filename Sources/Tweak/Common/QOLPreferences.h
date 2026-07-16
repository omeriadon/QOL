@import Foundation;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const QOLDefaultsSuite;
FOUNDATION_EXPORT NSString *const QOLSettingsDidChangeNotification;
FOUNDATION_EXPORT NSString *const QOLMusicPulsePreviewNotification;
FOUNDATION_EXPORT NSString *const QOLCommandLensPreviewNotification;

FOUNDATION_EXPORT NSUserDefaults *QOLDefaults(void);
FOUNDATION_EXPORT BOOL QOLBool(NSString *key, BOOL fallback);
FOUNDATION_EXPORT double QOLDouble(NSString *key, double fallback);
FOUNDATION_EXPORT NSInteger QOLInteger(NSString *key, NSInteger fallback);

NS_ASSUME_NONNULL_END
