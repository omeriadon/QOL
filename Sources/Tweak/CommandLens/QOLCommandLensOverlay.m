#import "QOLCommandLensBadge.h"
#import "QOLCommandLensOverlay.h"

@implementation QOLCommandLensOverlay

- (NSView *)hitTest:(NSPoint)point {
    return nil;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSMutableArray<NSValue *> *occupiedFrames = [NSMutableArray array];

    NSDictionary<NSAttributedStringKey, id> *assignedAttributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11.0 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: NSColor.whiteColor
    };
    NSDictionary<NSAttributedStringKey, id> *actionAttributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:10.0 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithWhite:0.94 alpha:1.0]
    };

    for (QOLCommandLensBadge *badge in self.badges) {
        NSDictionary *attributes = badge.assignedShortcut ? assignedAttributes : actionAttributes;
        NSSize textSize = [badge.title sizeWithAttributes:attributes];
        NSSize badgeSize = NSMakeSize(textSize.width + 12.0, textSize.height + 7.0);
        NSRect frame = NSMakeRect(badge.anchor.x - badgeSize.width * 0.5,
                                  badge.anchor.y - badgeSize.height - 6.0,
                                  badgeSize.width,
                                  badgeSize.height);
        frame.origin.x = MIN(MAX(frame.origin.x, 4.0), NSWidth(self.bounds) - NSWidth(frame) - 4.0);
        frame.origin.y = MIN(MAX(frame.origin.y, 4.0), NSHeight(self.bounds) - NSHeight(frame) - 4.0);
        for (NSInteger attempt = 0; attempt < 6; attempt++) {
            BOOL intersects = NO;
            for (NSValue *value in occupiedFrames) {
                if (NSIntersectsRect(NSInsetRect(frame, -2.0, -2.0), value.rectValue)) {
                    intersects = YES;
                    break;
                }
            }
            if (!intersects) break;
            frame.origin.y = MAX(4.0, frame.origin.y - NSHeight(frame) - 5.0);
        }
        [occupiedFrames addObject:[NSValue valueWithRect:frame]];

        NSColor *fill = badge.assignedShortcut
            ? [NSColor colorWithRed:0.88 green:0.08 blue:0.12 alpha:self.badgeOpacity]
            : [NSColor colorWithWhite:0.08 alpha:self.badgeOpacity * 0.92];
        [fill setFill];
        [[NSBezierPath bezierPathWithRoundedRect:frame xRadius:6.0 yRadius:6.0] fill];

        NSRect textFrame = NSMakeRect(NSMinX(frame) + 6.0,
                                      NSMinY(frame) + 3.5,
                                      textSize.width,
                                      textSize.height);
        [badge.title drawInRect:textFrame withAttributes:attributes];
    }
}

@end
