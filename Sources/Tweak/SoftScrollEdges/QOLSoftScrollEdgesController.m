@import AppKit;

#import <objc/message.h>
#import <objc/runtime.h>

#import "QOLPreferences.h"
#import "QOLSoftScrollEdgesController.h"

static void (*QOLOriginalDidAddSubview)(id, SEL, NSView *);
static void (*QOLOriginalTitlebarStyleSetter)(id, SEL, id);
static void (*QOLOriginalSplitAccessoryStyleSetter)(id, SEL, id);
static NSUInteger QOLSoftStyleApplicationCount;

static id QOLSoftStyle(void) {
    Class styleClass = NSClassFromString(@"NSScrollEdgeEffectStyle");
    SEL selector = NSSelectorFromString(@"softStyle");
    return [styleClass respondsToSelector:selector]
        ? ((id (*)(id, SEL))objc_msgSend)(styleClass, selector)
        : nil;
}

static void QOLApplyStyleToObject(id object) {
    if (!object || !QOLBool(@"softScrollEdgesEnabled", YES)) return;
    id softStyle = QOLSoftStyle();
    if (!softStyle) return;

    for (NSString *name in @[@"setPreferredScrollEdgeEffectStyle:", @"setScrollEdgeEffectStyle:", @"_setScrollEdgeEffectStyle:"]) {
        SEL setter = NSSelectorFromString(name);
        if ([object respondsToSelector:setter]) {
            ((void (*)(id, SEL, id))objc_msgSend)(object, setter, softStyle);
            QOLSoftStyleApplicationCount += 1;
        }
    }
}

static void QOLTraverseView(NSView *view) {
    if (!view) return;
    QOLApplyStyleToObject(view);
    if ([view isKindOfClass:NSScrollView.class]) {
        QOLApplyStyleToObject(((NSScrollView *)view).contentView);
        QOLApplyStyleToObject(((NSScrollView *)view).documentView);
    }
    for (NSView *subview in view.subviews.copy) QOLTraverseView(subview);
}

static void QOLTraverseViewController(NSViewController *controller) {
    if (!controller) return;
    QOLApplyStyleToObject(controller);
    QOLTraverseView(controller.viewIfLoaded);
    for (NSViewController *child in controller.childViewControllers) QOLTraverseViewController(child);

    if ([controller isKindOfClass:NSSplitViewController.class]) {
        for (NSSplitViewItem *item in ((NSSplitViewController *)controller).splitViewItems) {
            QOLApplyStyleToObject(item.viewController);
            SEL accessorySelector = NSSelectorFromString(@"accessoryViewController");
            if ([item respondsToSelector:accessorySelector]) {
                QOLApplyStyleToObject(((id (*)(id, SEL))objc_msgSend)(item, accessorySelector));
            }
        }
    }
}

static void QOLTraverseWindow(NSWindow *window) {
    QOLTraverseView(window.contentView);
    QOLTraverseViewController(window.contentViewController);
}

static void QOLDidAddSubview(id self, SEL command, NSView *subview) {
    if (QOLOriginalDidAddSubview) QOLOriginalDidAddSubview(self, command, subview);
    QOLTraverseView(subview);
}

static void QOLSetTitlebarStyle(id self, SEL command, id style) {
    id resolvedStyle = QOLBool(@"softScrollEdgesEnabled", YES) ? QOLSoftStyle() : style;
    if (QOLOriginalTitlebarStyleSetter) QOLOriginalTitlebarStyleSetter(self, command, resolvedStyle ?: style);
}

static void QOLSetSplitAccessoryStyle(id self, SEL command, id style) {
    id resolvedStyle = QOLBool(@"softScrollEdgesEnabled", YES) ? QOLSoftStyle() : style;
    if (QOLOriginalSplitAccessoryStyleSetter) QOLOriginalSplitAccessoryStyleSetter(self, command, resolvedStyle ?: style);
}

static void QOLForceSetterOnClass(Class cls, IMP replacement, void (**original)(id, SEL, id)) {
    SEL setter = NSSelectorFromString(@"setPreferredScrollEdgeEffectStyle:");
    Method method = class_getInstanceMethod(cls, setter);
    if (!method) return;
    *original = (void (*)(id, SEL, id))method_getImplementation(method);
    method_setImplementation(method, replacement);
}

@interface QOLSoftScrollEdgesController ()
- (void)refresh:(NSNotification *)notification;
@end

@implementation QOLSoftScrollEdgesController

+ (instancetype)sharedController {
    static QOLSoftScrollEdgesController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ controller = [QOLSoftScrollEdgesController new]; });
    return controller;
}

+ (void)install {
    NSUserDefaults *diagnostics = QOLDefaults();
    [diagnostics setObject:NSDate.date forKey:@"softScrollEdgesInstalledDate"];
    [diagnostics setBool:QOLSoftStyle() != nil forKey:@"softScrollEdgesStyleAvailable"];
    Method method = class_getInstanceMethod(NSView.class, @selector(didAddSubview:));
    if (method) {
        QOLOriginalDidAddSubview = (void (*)(id, SEL, NSView *))method_getImplementation(method);
        method_setImplementation(method, (IMP)QOLDidAddSubview);
    }

    QOLForceSetterOnClass(NSClassFromString(@"NSTitlebarAccessoryViewController"),
                          (IMP)QOLSetTitlebarStyle,
                          &QOLOriginalTitlebarStyleSetter);
    QOLForceSetterOnClass(NSClassFromString(@"NSSplitViewItemAccessoryViewController"),
                          (IMP)QOLSetSplitAccessoryStyle,
                          &QOLOriginalSplitAccessoryStyleSetter);

    QOLSoftScrollEdgesController *controller = self.sharedController;
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:controller selector:@selector(refresh:) name:NSWindowDidBecomeKeyNotification object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(refresh:)
                                                           name:QOLSettingsDidChangeNotification
                                                         object:nil];
    [controller refresh:nil];
}

- (void)refresh:(NSNotification *)notification {
    for (NSWindow *window in NSApp.windows.copy) QOLTraverseWindow(window);
    NSUserDefaults *diagnostics = QOLDefaults();
    [diagnostics setInteger:QOLSoftStyleApplicationCount forKey:@"softScrollEdgesApplicationCount"];
    [diagnostics setObject:NSDate.date forKey:@"softScrollEdgesLastTraversalDate"];
}

@end
