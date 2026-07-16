@import AppKit;
@import QuartzCore;

#import "QOLCommandLensBadge.h"
#import "QOLCommandLensController.h"
#import "QOLCommandLensOverlay.h"
#import "QOLPreferences.h"

@interface QOLCommandLensController ()
@property (nonatomic, strong) id flagsMonitor;
@property (nonatomic, strong) id keyMonitor;
@property (nonatomic, strong, nullable) QOLCommandLensOverlay *overlay;
@property (nonatomic) BOOL commandHeld;
@property (nonatomic) NSUInteger revealGeneration;
@end


@implementation QOLCommandLensController

+ (instancetype)sharedController {
    static QOLCommandLensController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ controller = [QOLCommandLensController new]; });
    return controller;
}

+ (void)install {
    QOLCommandLensController *controller = self.sharedController;
    controller.flagsMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                                                     handler:^NSEvent *(NSEvent *event) {
        [controller modifierFlagsDidChange:event.modifierFlags];
        return event;
    }];
    controller.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                                                   handler:^NSEvent *(NSEvent *event) {
        if (controller.commandHeld) [controller hideLens];
        return event;
    }];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(settingsDidChange:)
                                                           name:QOLSettingsDidChangeNotification
                                                         object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(previewCommandLens:)
                                                           name:QOLCommandLensPreviewNotification
                                                         object:nil];
}

- (void)settingsDidChange:(NSNotification *)notification {
    if (!QOLBool(@"commandLensEnabled", YES)) [self hideLens];
}

- (void)previewCommandLens:(NSNotification *)notification {
    [self showLens];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self hideLens];
    });
}

- (void)modifierFlagsDidChange:(NSEventModifierFlags)flags {
    BOOL commandIsHeld = (flags & NSEventModifierFlagCommand) != 0;
    if (commandIsHeld == self.commandHeld) return;
    self.commandHeld = commandIsHeld;
    self.revealGeneration += 1;

    if (!commandIsHeld) {
        [self hideLens];
        return;
    }
    if (!QOLBool(@"commandLensEnabled", YES)) return;

    NSUInteger generation = self.revealGeneration;
    NSTimeInterval delay = MIN(MAX(QOLDouble(@"commandLensHoldDelay", 0.45), 0.15), 1.5);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (self.commandHeld && self.revealGeneration == generation) [self showLens];
    });
}

- (void)showLens {
    NSWindow *window = NSApp.keyWindow ?: NSApp.mainWindow;
    NSView *contentView = window.contentView;
    NSView *rootView = contentView.superview ?: contentView;
    if (!window || !rootView) return;

    NSArray<QOLCommandLensBadge *> *badges = [self badgesInView:rootView rootView:rootView];
    if (badges.count == 0) return;

    QOLCommandLensOverlay *overlay = [[QOLCommandLensOverlay alloc] initWithFrame:rootView.bounds];
    overlay.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    overlay.badges = badges;
    overlay.badgeOpacity = MIN(MAX(QOLDouble(@"commandLensOpacity", 0.9), 0.35), 1.0);
    overlay.alphaValue = 0.0;
    [rootView addSubview:overlay positioned:NSWindowAbove relativeTo:nil];
    self.overlay = overlay;

    BOOL reduceMotion = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = reduceMotion ? 0.08 : 0.16;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        overlay.animator.alphaValue = 1.0;
    }];
}

- (void)hideLens {
    QOLCommandLensOverlay *overlay = self.overlay;
    self.overlay = nil;
    if (!overlay) return;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.1;
        overlay.animator.alphaValue = 0.0;
    } completionHandler:^{
        [overlay removeFromSuperview];
    }];
}

- (NSArray<QOLCommandLensBadge *> *)badgesInView:(NSView *)view rootView:(NSView *)rootView {
    NSMutableArray<QOLCommandLensBadge *> *badges = [NSMutableArray array];
    NSHashTable *visited = [NSHashTable hashTableWithOptions:NSPointerFunctionsObjectPointerPersonality];
    [self appendBadgesFromAccessibilityElement:view.window
                                        window:view.window
                                      rootView:rootView
                                       visited:visited
                                       toArray:badges
                                         depth:0];
    return badges;
}

- (void)appendBadgesFromAccessibilityElement:(id)element
                                      window:(NSWindow *)window
                                    rootView:(NSView *)rootView
                                     visited:(NSHashTable *)visited
                                     toArray:(NSMutableArray<QOLCommandLensBadge *> *)badges
                                       depth:(NSInteger)depth {
    if (!element || depth > 14 || [visited containsObject:element]) return;
    [visited addObject:element];

    NSString *role = [element respondsToSelector:@selector(accessibilityRole)]
        ? [element accessibilityRole]
        : nil;
    NSSet<NSString *> *controlRoles = [NSSet setWithArray:@[
        NSAccessibilityButtonRole,
        NSAccessibilityPopUpButtonRole,
        NSAccessibilityMenuButtonRole,
        NSAccessibilityRadioButtonRole,
        NSAccessibilityCheckBoxRole
    ]];

    if ([controlRoles containsObject:role]) {
        NSString *label = [element respondsToSelector:@selector(accessibilityLabel)]
            ? [element accessibilityLabel]
            : nil;
        if (label.length == 0 && [element respondsToSelector:@selector(accessibilityTitle)]) {
            label = [element accessibilityTitle];
        }
        if (label.length == 0 && [element respondsToSelector:@selector(accessibilityHelp)]) {
            label = [element accessibilityHelp];
        }

        NSString *shortcut = @"";
        if ([element isKindOfClass:NSControl.class]) {
            SEL action = [(NSControl *)element action];
            if (action) shortcut = [self shortcutForAction:action inMenu:NSApp.mainMenu];
        }
        if (shortcut.length == 0 && label.length > 0) {
            shortcut = [self shortcutForTitle:label inMenu:NSApp.mainMenu];
        }

        BOOL assigned = shortcut.length > 0;
        NSString *title = assigned ? shortcut : label;
        if (!assigned && !QOLBool(@"commandLensShowUnassigned", YES)) title = @"";

        if (title.length > 0 && [element respondsToSelector:@selector(accessibilityFrame)]) {
            NSRect screenFrame = [element accessibilityFrame];
            if (!NSIsEmptyRect(screenFrame) && NSIntersectsRect(screenFrame, window.screen.frame)) {
                NSPoint windowPoint = [window convertPointFromScreen:screenFrame.origin];
                NSPoint localOrigin = [rootView convertPoint:windowPoint fromView:nil];
                NSRect frame = NSMakeRect(localOrigin.x,
                                          localOrigin.y,
                                          NSWidth(screenFrame),
                                          NSHeight(screenFrame));
                if (title.length > 28) title = [[title substringToIndex:27] stringByAppendingString:@"…"];
                QOLCommandLensBadge *badge = [QOLCommandLensBadge new];
                badge.anchor = NSMakePoint(NSMidX(frame), NSMinY(frame));
                badge.title = title;
                badge.assignedShortcut = assigned;
                [badges addObject:badge];
            }
        }
    }

    NSArray *children = [element respondsToSelector:@selector(accessibilityChildren)]
        ? [element accessibilityChildren]
        : nil;
    for (id child in children) {
        [self appendBadgesFromAccessibilityElement:child
                                            window:window
                                          rootView:rootView
                                           visited:visited
                                           toArray:badges
                                             depth:depth + 1];
    }
}

- (NSString *)shortcutForAction:(SEL)action inMenu:(NSMenu *)menu {
    for (NSMenuItem *item in menu.itemArray) {
        if (item.action == action && item.keyEquivalent.length > 0) {
            return [self displayShortcutForMenuItem:item];
        }
        NSString *nested = item.submenu ? [self shortcutForAction:action inMenu:item.submenu] : nil;
        if (nested.length > 0) return nested;
    }
    return @"";
}

- (NSString *)shortcutForTitle:(NSString *)title inMenu:(NSMenu *)menu {
    NSString *normalizedTitle = title.lowercaseString;
    for (NSMenuItem *item in menu.itemArray) {
        NSString *menuTitle = item.title.lowercaseString;
        if (item.keyEquivalent.length > 0 &&
            ([menuTitle isEqualToString:normalizedTitle] ||
             [menuTitle hasPrefix:normalizedTitle] ||
             [normalizedTitle hasPrefix:menuTitle])) {
            return [self displayShortcutForMenuItem:item];
        }
        NSString *nested = item.submenu ? [self shortcutForTitle:title inMenu:item.submenu] : nil;
        if (nested.length > 0) return nested;
    }
    return @"";
}

- (NSString *)displayShortcutForMenuItem:(NSMenuItem *)item {
    NSMutableString *result = [NSMutableString string];
    NSEventModifierFlags flags = item.keyEquivalentModifierMask;
    if (flags & NSEventModifierFlagControl) [result appendString:@"⌃"];
    if (flags & NSEventModifierFlagOption) [result appendString:@"⌥"];
    if (flags & NSEventModifierFlagShift) [result appendString:@"⇧"];
    if (flags & NSEventModifierFlagCommand) [result appendString:@"⌘"];
    [result appendString:item.keyEquivalent.uppercaseString];
    return result;
}

@end
