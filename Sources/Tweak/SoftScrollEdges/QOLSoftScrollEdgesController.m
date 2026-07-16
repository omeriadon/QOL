@import AppKit;

#import <objc/message.h>
#import <objc/runtime.h>

#import "QOLPreferences.h"
#import "QOLSoftScrollEdgesController.h"
#import "QOLSymbolRebinder.h"

static void (*QOLOriginalDidAddSubview)(id, SEL, NSView *);
static void (*QOLOriginalTitlebarStyleSetter)(id, SEL, id);
static void (*QOLOriginalSplitAccessoryStyleSetter)(id, SEL, id);
static id (*QOLOriginalAutomaticStyleGetter)(id, SEL);
static id (*QOLOriginalHardStyleGetter)(id, SEL);
static NSUInteger QOLSoftStyleApplicationCount;
static NSUInteger QOLSwiftUIStyleOverrideCount;
static NSUInteger QOLPocketStyleOverrideCount;
static NSMutableDictionary<NSString *, NSValue *> *QOLOriginalPocketStyleImplementations;
static BOOL QOLRescannedAfterSwiftUIView;
static NSInteger QOLSoftPocketStyleValue = 500;

static id QOLSoftStyle(void) {
    Class styleClass = NSClassFromString(@"NSScrollEdgeEffectStyle");
    SEL selector = NSSelectorFromString(@"softStyle");
    return [styleClass respondsToSelector:selector]
        ? ((id (*)(id, SEL))objc_msgSend)(styleClass, selector)
        : nil;
}

static id QOLAutomaticStyle(id self, SEL command) {
    if (QOLBool(@"softScrollEdgesEnabled", YES)) return QOLSoftStyle();
    return QOLOriginalAutomaticStyleGetter ? QOLOriginalAutomaticStyleGetter(self, command) : nil;
}

static id QOLHardStyle(id self, SEL command) {
    if (QOLBool(@"softScrollEdgesEnabled", YES)) return QOLSoftStyle();
    return QOLOriginalHardStyleGetter ? QOLOriginalHardStyleGetter(self, command) : nil;
}

static uint8_t QOLSwiftUIAutomaticStyle(void) {
    if (QOLBool(@"softScrollEdgesEnabled", YES)) {
        QOLSwiftUIStyleOverrideCount += 1;
        // ScrollEdgeEffectStyle is a one-byte value on macOS 26 and 27: automatic 0, hard 1, soft 2.
        return 2;
    }
    return 0;
}

static uint8_t QOLSwiftUIHardStyle(void) {
    if (QOLBool(@"softScrollEdgesEnabled", YES)) {
        QOLSwiftUIStyleOverrideCount += 1;
        return 2;
    }
    return 1;
}

static void QOLInstallStyleSourceOverrides(void) {
    Class styleClass = NSClassFromString(@"NSScrollEdgeEffectStyle");
    Method automaticMethod = class_getClassMethod(styleClass, NSSelectorFromString(@"automaticStyle"));
    Method hardMethod = class_getClassMethod(styleClass, NSSelectorFromString(@"hardStyle"));
    if (automaticMethod) {
        QOLOriginalAutomaticStyleGetter = (id (*)(id, SEL))method_setImplementation(automaticMethod,
                                                                                   (IMP)QOLAutomaticStyle);
    }
    if (hardMethod) {
        QOLOriginalHardStyleGetter = (id (*)(id, SEL))method_setImplementation(hardMethod,
                                                                              (IMP)QOLHardStyle);
    }

    QOLSymbolRebinding rebindings[] = {
        {
            "$s7SwiftUI21ScrollEdgeEffectStyleV9automaticACvgZ",
            (void *)QOLSwiftUIAutomaticStyle,
        },
        {
            "$s7SwiftUI21ScrollEdgeEffectStyleV4hardACvgZ",
            (void *)QOLSwiftUIHardStyle,
        },
    };
    QOLRebindSymbols(rebindings, sizeof(rebindings) / sizeof(rebindings[0]));
}

static NSInteger QOLPocketElementStyle(id self, SEL command) {
    if (QOLBool(@"softScrollEdgesEnabled", YES)) {
        QOLPocketStyleOverrideCount += 1;
        if (QOLPocketStyleOverrideCount == 1) {
            NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
            NSString *diagnosticKey = [@"softScrollEdgesPocketUsed." stringByAppendingString:bundleIdentifier];
            [QOLDefaults() setObject:NSDate.date forKey:diagnosticKey];
        }
        return QOLSoftPocketStyleValue;
    }

    Class cls = object_getClass(self);
    while (cls) {
        NSValue *implementationValue = QOLOriginalPocketStyleImplementations[NSStringFromClass(cls)];
        if (implementationValue) {
            NSInteger (*implementation)(id, SEL) = (NSInteger (*)(id, SEL))implementationValue.pointerValue;
            return implementation(self, command);
        }
        cls = class_getSuperclass(cls);
    }
    return 1000;
}

static void QOLInstallPocketStyleOverrides(void) {
    SEL selector = NSSelectorFromString(@"_scrollPocketElementStyle");
    id softStyle = QOLSoftStyle();
    SEL equivalentValueSelector = NSSelectorFromString(@"_equivalentAccessoryBarBackgroundValue");
    if ([softStyle respondsToSelector:equivalentValueSelector]) {
        QOLSoftPocketStyleValue = ((NSInteger (*)(id, SEL))objc_msgSend)(softStyle,
                                                                        equivalentValueSelector);
    }
    if (!QOLOriginalPocketStyleImplementations) {
        QOLOriginalPocketStyleImplementations = [NSMutableDictionary dictionary];
    }
    int classCount = objc_getClassList(NULL, 0);
    if (classCount <= 0) return;
    Class *classes = (Class *)calloc((size_t)classCount, sizeof(Class));
    classCount = objc_getClassList(classes, classCount);
    for (int index = 0; index < classCount; index++) {
        Class cls = classes[index];
        NSString *className = NSStringFromClass(cls);
        if (QOLOriginalPocketStyleImplementations[className]) continue;
        unsigned int methodCount = 0;
        Method *methods = class_copyMethodList(cls, &methodCount);
        for (unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
            Method method = methods[methodIndex];
            if (method_getName(method) != selector) continue;
            IMP original = method_setImplementation(method, (IMP)QOLPocketElementStyle);
            QOLOriginalPocketStyleImplementations[className] = [NSValue valueWithPointer:original];
            break;
        }
        free(methods);
    }
    free(classes);
    [QOLDefaults() setInteger:QOLOriginalPocketStyleImplementations.count
                       forKey:@"softScrollEdgesPocketHookCount"];
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
    if (!QOLRescannedAfterSwiftUIView &&
        [NSStringFromClass(subview.class) rangeOfString:@"SwiftUI"].location != NSNotFound) {
        QOLRescannedAfterSwiftUIView = YES;
        QOLInstallPocketStyleOverrides();
    }
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
    QOLInstallStyleSourceOverrides();
    QOLInstallPocketStyleOverrides();
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
    [diagnostics setInteger:QOLSwiftUIStyleOverrideCount forKey:@"softScrollEdgesSwiftUIOverrideCount"];
    [diagnostics setInteger:QOLPocketStyleOverrideCount forKey:@"softScrollEdgesPocketOverrideCount"];
    [diagnostics setObject:NSDate.date forKey:@"softScrollEdgesLastTraversalDate"];
}

@end
