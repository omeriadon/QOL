@import AppKit;

NS_ASSUME_NONNULL_BEGIN

@interface QOLCommandLensBadge : NSObject
@property (nonatomic) NSPoint anchor;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) BOOL assignedShortcut;
@end

NS_ASSUME_NONNULL_END

