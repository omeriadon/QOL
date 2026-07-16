@import AppKit;

@class QOLCommandLensBadge;

NS_ASSUME_NONNULL_BEGIN

@interface QOLCommandLensOverlay : NSView
@property (nonatomic, copy) NSArray<QOLCommandLensBadge *> *badges;
@property (nonatomic) CGFloat badgeOpacity;
@end

NS_ASSUME_NONNULL_END

