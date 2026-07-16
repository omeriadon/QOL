@import AppKit;

#import "QOLAppCapsuleController.h"
#import "QOLPreferences.h"

@interface QOLAppCapsuleController ()
@property (nonatomic, weak) NSMenuItem *applicationMenuItem;
@property (nonatomic, copy) NSString *originalTitle;
@property (nonatomic, copy, nullable) NSAttributedString *originalAttributedTitle;
@end

@implementation QOLAppCapsuleController

+ (instancetype)sharedController {
    static QOLAppCapsuleController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ controller = [QOLAppCapsuleController new]; });
    return controller;
}

+ (void)install {
    QOLAppCapsuleController *controller = self.sharedController;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:controller selector:@selector(windowStateDidChange:) name:NSWindowDidBecomeKeyNotification object:nil];
    [center addObserver:controller selector:@selector(windowStateDidChange:) name:NSWindowDidUpdateNotification object:nil];
    [center addObserver:controller selector:@selector(windowStateDidChange:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(settingsDidChange:)
                                                           name:QOLSettingsDidChangeNotification
                                                         object:nil];
    [controller updateCapsule];
}

- (void)settingsDidChange:(NSNotification *)notification {
    [self updateCapsule];
}

- (void)windowStateDidChange:(NSNotification *)notification {
    [self updateCapsule];
}

- (void)captureApplicationMenuItemIfNeeded {
    NSMenuItem *item = [NSApp.mainMenu itemAtIndex:0];
    if (!item || item == self.applicationMenuItem) return;
    self.applicationMenuItem = item;
    self.originalTitle = item.title ?: @"";
    self.originalAttributedTitle = item.attributedTitle;
}

- (void)updateCapsule {
    [self captureApplicationMenuItemIfNeeded];
    NSMenuItem *item = self.applicationMenuItem;
    if (!item) return;

    if (!QOLBool(@"appCapsuleEnabled", YES)) {
        item.title = self.originalTitle;
        item.attributedTitle = self.originalAttributedTitle;
        return;
    }

    NSWindow *window = NSApp.keyWindow ?: NSApp.mainWindow;
    BOOL edited = window.documentEdited;
    NSString *applicationName = NSProcessInfo.processInfo.processName;
    NSString *documentName = @"";
    if (QOLBool(@"appCapsuleShowDocument", YES) && window) {
        documentName = window.representedURL.lastPathComponent.stringByDeletingPathExtension ?: @"";
        if (documentName.length == 0 && window.title.length > 0 && ![window.title isEqualToString:applicationName]) {
            documentName = window.title;
        }
    }

    NSString *label = applicationName;
    if (documentName.length > 0) label = [NSString stringWithFormat:@"%@  ·  %@", applicationName, documentName];
    if (label.length > 38) label = [[label substringToIndex:37] stringByAppendingString:@"…"];

    NSImage *capsule = [self capsuleImageWithLabel:label
                                           edited:edited && QOLBool(@"appCapsuleShowUnsaved", YES)];
    NSTextAttachment *attachment = [NSTextAttachment new];
    attachment.image = capsule;
    attachment.bounds = NSMakeRect(0.0, -4.0, capsule.size.width, capsule.size.height);
    item.attributedTitle = [NSAttributedString attributedStringWithAttachment:attachment];
    item.accessibilityLabel = applicationName;
}

- (NSImage *)capsuleImageWithLabel:(NSString *)label edited:(BOOL)edited {
    NSImage *icon = NSApp.applicationIconImage;
    NSFont *font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightSemibold];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: NSColor.labelColor
    };
    NSSize textSize = [label sizeWithAttributes:attributes];
    CGFloat dirtyWidth = edited ? 11.0 : 0.0;
    NSSize size = NSMakeSize(8.0 + 16.0 + 6.0 + textSize.width + dirtyWidth + 9.0, 22.0);

    return [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect destinationRect) {
        NSColor *fill = [NSColor colorWithWhite:0.5 alpha:0.16];
        [fill setFill];
        [[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(destinationRect, 0.5, 1.0)
                                         xRadius:10.0
                                         yRadius:10.0] fill];

        [icon drawInRect:NSMakeRect(8.0, 3.0, 16.0, 16.0)
                fromRect:NSZeroRect
               operation:NSCompositingOperationSourceOver
                fraction:1.0];
        [label drawAtPoint:NSMakePoint(30.0, 4.0) withAttributes:attributes];

        if (edited) {
            [[NSColor colorWithRed:1.0 green:0.12 blue:0.16 alpha:1.0] setFill];
            NSRect dot = NSMakeRect(size.width - 12.0, 8.0, 6.0, 6.0);
            [[NSBezierPath bezierPathWithOvalInRect:dot] fill];
        }
        return YES;
    }];
}

@end
