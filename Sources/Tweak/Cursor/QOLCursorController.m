@import AppKit;

#import <objc/runtime.h>

#import "QOLCursorController.h"
#import "QOLPreferences.h"

static NSCursor *QOLCustomArrowCursor;
static NSCursor *(*QOLOriginalArrowCursor)(id, SEL);

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
        method_setImplementation(method, (IMP)QOLArrowCursor);
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
