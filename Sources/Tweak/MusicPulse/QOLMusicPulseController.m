@import AppKit;
@import QuartzCore;

#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "QOLMusicPulseController.h"
#import "QOLPreferences.h"

static NSString *const QOLMusicBundleIdentifier = @"com.apple.Music";
static NSString *const QOLMusicPulseLayerName = @"com.omeriadon.QOL.musicPulse";

static void (*QOLOriginalTileRender)(id, SEL);
static void (*QOLOriginalTileUpdateRect)(id, SEL);
static NSHashTable *QOLMusicTiles;
static BOOL QOLMusicIsPlaying;
static NSDate *QOLMusicPreviewEndDate;
static BOOL QOLMusicPulseEnabled;
static NSInteger QOLMusicRingCount;
static CGFloat QOLMusicRingOpacity;
static CGFloat QOLMusicRingExpansion;
static CGFloat QOLMusicRingDuration;
static CGFloat QOLMusicRingWidth;

typedef void (*MRGetPlayingFunction)(dispatch_queue_t, void (^)(Boolean));
typedef void (*MRGetPIDFunction)(dispatch_queue_t, void (^)(int));

static MRGetPlayingFunction QOLGetPlaying;
static MRGetPIDFunction QOLGetPID;

static CALayer *QOLTileLayer(id tile) {
    Ivar ivar = class_getInstanceVariable([tile class], "_layer");
    if (!ivar) return nil;
    id value = object_getIvar(tile, ivar);
    return [value isKindOfClass:CALayer.class] ? value : nil;
}

static NSString *QOLTileBundleIdentifier(id tile) {
    SEL selector = NSSelectorFromString(@"bundleIdentifier");
    if (![tile respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(tile, selector);
}

static CALayer *QOLImageLayer(CALayer *tileLayer) {
    SEL selector = NSSelectorFromString(@"imageLayer");
    if (![tileLayer respondsToSelector:selector]) return nil;
    id value = ((id (*)(id, SEL))objc_msgSend)(tileLayer, selector);
    return [value isKindOfClass:CALayer.class] ? value : nil;
}

static void QOLLoadMusicPulseSettings(void) {
    QOLMusicPulseEnabled = QOLBool(@"musicPulseEnabled", YES);
    QOLMusicRingCount = MIN(MAX(QOLInteger(@"musicPulseRingCount", 3), 1), 6);
    QOLMusicRingOpacity = MIN(MAX(QOLDouble(@"musicPulseOpacity", 0.72), 0.1), 1.0);
    QOLMusicRingExpansion = MIN(MAX(QOLDouble(@"musicPulseExpansion", 1.34), 1.05), 1.8);
    QOLMusicRingDuration = MIN(MAX(QOLDouble(@"musicPulseDuration", 1.8), 0.6), 4.0);
    QOLMusicRingWidth = MIN(MAX(QOLDouble(@"musicPulseLineWidth", 2.0), 0.5), 8.0);
}

static CALayer *QOLFindPulseContainer(CALayer *tileLayer) {
    for (CALayer *layer in tileLayer.sublayers.copy) {
        if ([layer.name isEqualToString:QOLMusicPulseLayerName]) return layer;
    }
    return nil;
}

static void QOLRemovePulse(CALayer *tileLayer) {
    [QOLFindPulseContainer(tileLayer) removeFromSuperlayer];
}

static void QOLAddRingAnimation(CAShapeLayer *ring, NSInteger index) {
    CGFloat delay = QOLMusicRingDuration / MAX(QOLMusicRingCount, 1);
    CFTimeInterval begin = CACurrentMediaTime() + (delay * index);

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @0.92;
    scale.toValue = @(QOLMusicRingExpansion);

    CAKeyframeAnimation *opacity = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacity.values = @[@0.0, @(QOLMusicRingOpacity), @(QOLMusicRingOpacity * 0.42), @0.0];
    opacity.keyTimes = @[@0.0, @0.12, @0.62, @1.0];

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[scale, opacity];
    group.duration = QOLMusicRingDuration;
    group.beginTime = begin;
    group.repeatCount = HUGE_VALF;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    group.removedOnCompletion = NO;
    [ring addAnimation:group forKey:@"qol.musicPulse.emission"];
}

static void QOLUpdatePulseForTile(id tile) {
    CALayer *tileLayer = QOLTileLayer(tile);
    CALayer *imageLayer = QOLImageLayer(tileLayer);
    if (!tileLayer || !imageLayer) return;

    BOOL previewing = [QOLMusicPreviewEndDate timeIntervalSinceNow] > 0.0;
    if (!QOLMusicPulseEnabled || (!QOLMusicIsPlaying && !previewing)) {
        QOLRemovePulse(tileLayer);
        return;
    }

    QOLRemovePulse(tileLayer);

    CALayer *container = [CALayer layer];
    container.name = QOLMusicPulseLayerName;
    container.frame = tileLayer.bounds;
    container.masksToBounds = NO;
    container.actions = @{@"bounds": NSNull.null, @"position": NSNull.null};

    CGRect iconFrame = imageLayer.frame;
    CGFloat side = MAX(CGRectGetWidth(iconFrame), CGRectGetHeight(iconFrame));
    CGRect ringFrame = CGRectMake(CGRectGetMidX(iconFrame) - side * 0.5,
                                  CGRectGetMidY(iconFrame) - side * 0.5,
                                  side,
                                  side);

    for (NSInteger index = 0; index < QOLMusicRingCount; index++) {
        CAShapeLayer *ring = [CAShapeLayer layer];
        ring.frame = ringFrame;
        ring.path = [NSBezierPath bezierPathWithOvalInRect:NSRectFromCGRect(CGRectInset(ring.bounds,
                                                                                       QOLMusicRingWidth,
                                                                                       QOLMusicRingWidth))].CGPath;
        ring.fillColor = NSColor.clearColor.CGColor;
        ring.strokeColor = [NSColor colorWithRed:1.0 green:0.08 blue:0.12 alpha:1.0].CGColor;
        ring.lineWidth = QOLMusicRingWidth;
        ring.opacity = 0.0;
        ring.shadowColor = [NSColor colorWithRed:1.0 green:0.0 blue:0.08 alpha:1.0].CGColor;
        ring.shadowOpacity = 0.45;
        ring.shadowRadius = 5.0;
        ring.shadowOffset = CGSizeZero;
        [container addSublayer:ring];
        QOLAddRingAnimation(ring, index);
    }

    [tileLayer insertSublayer:container below:imageLayer];
    NSUserDefaults *diagnostics = QOLDefaults();
    [diagnostics setObject:NSDate.date forKey:@"musicPulseLastEmissionDate"];
    [diagnostics setInteger:QOLMusicRingCount forKey:@"musicPulseLastEmissionRingCount"];
}

static void QOLRefreshAllMusicTiles(void) {
    for (id tile in QOLMusicTiles.allObjects) QOLUpdatePulseForTile(tile);
}

static void QOLObserveTile(id tile) {
    if (![QOLTileBundleIdentifier(tile) isEqualToString:QOLMusicBundleIdentifier]) return;
    [QOLDefaults() setObject:NSDate.date forKey:@"musicPulseMusicTileDetectedDate"];
    [QOLMusicTiles addObject:tile];
    QOLUpdatePulseForTile(tile);
}

static void QOLTileRender(id self, SEL command) {
    if (QOLOriginalTileRender) QOLOriginalTileRender(self, command);
    QOLObserveTile(self);
}

static void QOLTileUpdateRect(id self, SEL command) {
    if (QOLOriginalTileUpdateRect) QOLOriginalTileUpdateRect(self, command);
    QOLObserveTile(self);
}

static IMP QOLReplaceOwnedMethod(Class cls, SEL selector, IMP replacement) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    Method owned = NULL;
    for (unsigned int index = 0; index < count; index++) {
        if (method_getName(methods[index]) == selector) {
            owned = methods[index];
            break;
        }
    }
    free(methods);
    return owned ? method_setImplementation(owned, replacement) : NULL;
}

@interface QOLMusicPulseController ()
@property (nonatomic, strong) id playerInfoObserver;
@end

@implementation QOLMusicPulseController

+ (instancetype)sharedController {
    static QOLMusicPulseController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ controller = [QOLMusicPulseController new]; });
    return controller;
}

+ (void)install {
    QOLMusicTiles = [NSHashTable weakObjectsHashTable];
    QOLLoadMusicPulseSettings();

    Class tileClass = NSClassFromString(@"Tile");
    QOLOriginalTileRender = (void (*)(id, SEL))QOLReplaceOwnedMethod(tileClass,
                                                                    NSSelectorFromString(@"render"),
                                                                    (IMP)QOLTileRender);
    QOLOriginalTileUpdateRect = (void (*)(id, SEL))QOLReplaceOwnedMethod(tileClass,
                                                                        NSSelectorFromString(@"updateRect"),
                                                                        (IMP)QOLTileUpdateRect);

    QOLMusicPulseController *controller = self.sharedController;
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(settingsDidChange:)
                                                           name:QOLSettingsDidChangeNotification
                                                         object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(musicPlayerInfoDidChange:)
                                                           name:@"com.apple.Music.playerInfo"
                                                         object:nil];
    [NSDistributedNotificationCenter.defaultCenter addObserver:controller
                                                       selector:@selector(previewMusicPulse:)
                                                           name:QOLMusicPulsePreviewNotification
                                                         object:nil];

    void *mediaRemote = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    if (mediaRemote) {
        QOLGetPlaying = (MRGetPlayingFunction)dlsym(mediaRemote, "MRMediaRemoteGetNowPlayingApplicationIsPlaying");
        QOLGetPID = (MRGetPIDFunction)dlsym(mediaRemote, "MRMediaRemoteGetNowPlayingApplicationPID");
    }

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:controller
                                   selector:@selector(pollPlayback:)
                                   userInfo:nil
                                    repeats:YES];
    [controller pollPlayback:nil];
}

- (void)settingsDidChange:(NSNotification *)notification {
    QOLLoadMusicPulseSettings();
    QOLRefreshAllMusicTiles();
}

- (void)musicPlayerInfoDidChange:(NSNotification *)notification {
    NSString *state = notification.userInfo[@"Player State"];
    if (!state) return;
    QOLMusicIsPlaying = [state caseInsensitiveCompare:@"Playing"] == NSOrderedSame;
    QOLRefreshAllMusicTiles();
}

- (void)previewMusicPulse:(NSNotification *)notification {
    QOLMusicPreviewEndDate = [NSDate dateWithTimeIntervalSinceNow:8.0];
    QOLRefreshAllMusicTiles();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        QOLRefreshAllMusicTiles();
    });
}

- (void)pollPlayback:(NSTimer *)timer {
    if (!QOLGetPlaying) return;
    QOLGetPlaying(dispatch_get_main_queue(), ^(Boolean playing) {
        if (!playing) {
            QOLMusicIsPlaying = NO;
            QOLRefreshAllMusicTiles();
            return;
        }

        if (!QOLGetPID) return;
        QOLGetPID(dispatch_get_main_queue(), ^(int pid) {
            NSRunningApplication *application = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
            BOOL musicIsPlaying = [application.bundleIdentifier isEqualToString:QOLMusicBundleIdentifier];
            if (musicIsPlaying != QOLMusicIsPlaying) {
                QOLMusicIsPlaying = musicIsPlaying;
                QOLRefreshAllMusicTiles();
            }
        });
    });
}

@end
