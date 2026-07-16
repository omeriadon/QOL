@import AppKit;

#import <objc/runtime.h>

#import "QOLCursorController.h"
#import "QOLPreferences.h"

static NSCursor *QOLCustomArrowCursor;
static NSCursor *QOLSystemArrowCursor;
static NSCursor *(*QOLOriginalArrowCursor)(id, SEL);
static void (*QOLOriginalCursorSet)(id, SEL);
static void (*QOLOriginalCursorPush)(id, SEL);
static void (*QOLOriginalClearOverrideAndSetArrow)(id, SEL);

static NSCursor *QOLBuildArrowCursor(void) {
    if (!QOLBool(@"cursorEnabled", YES)) {
        return QOLOriginalArrowCursor ? QOLOriginalArrowCursor(NSCursor.class, @selector(arrowCursor)) : nil;
    }

    NSColor *fill = [QOLColor(@"cursorFillColor", NSColor.blackColor)
        colorWithAlphaComponent:MIN(MAX(QOLDouble(@"cursorFillOpacity", 1.0), 0.05), 1.0)];
    NSColor *outline = [QOLColor(@"cursorOutlineColor", NSColor.whiteColor)
        colorWithAlphaComponent:MIN(MAX(QOLDouble(@"cursorOutlineOpacity", 0.92), 0.05), 1.0)];
    CGFloat outlineWidth = MIN(MAX(QOLDouble(@"cursorOutlineWidth", 1.5), 0.5), 5.0);
    BOOL outlineEnabled = QOLBool(@"cursorOutlineEnabled", YES);
    CGFloat cursorSize = MIN(MAX(QOLDouble(@"cursorSize", 22.0), 6.0), 64.0);
    CGFloat cornerRadius = MIN(MAX(QOLDouble(@"cursorCornerRadius", 11.0), 0.0), cursorSize * 0.5);
    CGFloat padding = outlineEnabled ? ceil(outlineWidth) : 0.0;
    CGFloat canvasSide = cursorSize + padding * 2.0;

    NSImage *image = [NSImage imageWithSize:NSMakeSize(canvasSide, canvasSide) flipped:YES drawingHandler:^BOOL(NSRect destinationRect) {
        NSRect shapeRect = NSInsetRect(destinationRect, padding, padding);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:shapeRect
                                                            xRadius:cornerRadius
                                                            yRadius:cornerRadius];
        path.lineJoinStyle = NSLineJoinStyleRound;
        path.lineCapStyle = NSLineCapStyleRound;
        [fill setFill];
        [path fill];
        if (outlineEnabled) {
            [outline setStroke];
            path.lineWidth = outlineWidth;
            [path stroke];
        }
        return YES;
    }];
    [QOLDefaults() setObject:NSDate.date forKey:@"cursorLastGeneratedDate"];
    return [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(canvasSide * 0.5, canvasSide * 0.5)];
}

static NSCursor *QOLArrowCursor(id self, SEL command) {
    if (!QOLCustomArrowCursor) QOLCustomArrowCursor = QOLBuildArrowCursor();
    return QOLCustomArrowCursor;
}

static NSCursor *QOLResolvedCursor(id cursor) {
    if (!QOLBool(@"cursorEnabled", YES) || cursor != QOLSystemArrowCursor) return cursor;
    if (!QOLCustomArrowCursor) QOLCustomArrowCursor = QOLBuildArrowCursor();
    return QOLCustomArrowCursor ?: cursor;
}

static void QOLCursorSet(id self, SEL command) {
    if (QOLOriginalCursorSet) QOLOriginalCursorSet(QOLResolvedCursor(self), command);
}

static void QOLCursorPush(id self, SEL command) {
    if (QOLOriginalCursorPush) QOLOriginalCursorPush(QOLResolvedCursor(self), command);
}

static void QOLClearOverrideAndSetArrow(id self, SEL command) {
    if (QOLOriginalClearOverrideAndSetArrow) QOLOriginalClearOverrideAndSetArrow(self, command);
    if (QOLBool(@"cursorEnabled", YES)) {
        if (!QOLCustomArrowCursor) QOLCustomArrowCursor = QOLBuildArrowCursor();
        [QOLCustomArrowCursor set];
    }
}

@interface QOLCursorController ()
- (void)settingsDidChange:(NSNotification *)notification;
@end

@implementation QOLCursorController

+ (instancetype)sharedController {
    static QOLCursorController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ controller = [QOLCursorController new]; });
    return controller;
}

+ (void)install {
    [QOLDefaults() setObject:NSDate.date forKey:@"cursorInstalledDate"];
    Method method = class_getClassMethod(NSCursor.class, @selector(arrowCursor));
    if (method) {
        QOLOriginalArrowCursor = (NSCursor *(*)(id, SEL))method_getImplementation(method);
        QOLSystemArrowCursor = QOLOriginalArrowCursor(NSCursor.class, @selector(arrowCursor));
        method_setImplementation(method, (IMP)QOLArrowCursor);
    }

    Method setMethod = class_getInstanceMethod(NSCursor.class, @selector(set));
    if (setMethod) {
        QOLOriginalCursorSet = (void (*)(id, SEL))method_setImplementation(setMethod, (IMP)QOLCursorSet);
    }
    Method pushMethod = class_getInstanceMethod(NSCursor.class, @selector(push));
    if (pushMethod) {
        QOLOriginalCursorPush = (void (*)(id, SEL))method_setImplementation(pushMethod, (IMP)QOLCursorPush);
    }
    Method clearMethod = class_getClassMethod(NSCursor.class, NSSelectorFromString(@"_clearOverrideCursorAndSetArrow"));
    if (clearMethod) {
        QOLOriginalClearOverrideAndSetArrow = (void (*)(id, SEL))method_setImplementation(
            clearMethod,
            (IMP)QOLClearOverrideAndSetArrow
        );
    }

    QOLCursorController *controller = self.sharedController;
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(settingsDidChange:)
                                                           name:QOLSettingsDidChangeNotification
                                                         object:nil];
    [[NSCursor arrowCursor] set];
}

- (void)settingsDidChange:(NSNotification *)notification {
    QOLCustomArrowCursor = nil;
    [[NSCursor arrowCursor] set];
}

@end
