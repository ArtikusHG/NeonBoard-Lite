#include "Neon.h"
#include <AppSupport/CPDistributedMessagingCenter.h>

@interface SBClockApplicationIconImageView : UIView
- (UIImage *)contentsImage;
- (void)_setAnimating:(BOOL)animating;
@end

NSArray *themes;
NSString *overrideTheme;

%group Themes

%hook SBClockApplicationIconImageView

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  NSMutableDictionary *files = [NSMutableDictionary dictionaryWithDictionary:@{
    @"ClockIconSecondHand" : @"seconds",
    @"ClockIconMinuteHand" : @"minutes",
    @"ClockIconHourHand" : @"hours",
    @"ClockIconBlackDot" : @"blackDot",
    @"ClockIconRedDot" : @"redDot",
    @"ClockIconHourMinuteDot" : @"blackDot",
    @"ClockIconSecondDot" : @"redDot"
  }];
  if (kCFCoreFoundationVersionNumber >= 1665.15) {
    [files setObject:@"hourMinuteDot" forKey:@"ClockIconBlackDot"];
    [files setObject:@"secondDot" forKey:@"ClockIconRedDot"];
    [files setObject:@"hourMinuteDot" forKey:@"ClockIconHourMinuteDot"];
    [files setObject:@"secondDot" forKey:@"ClockIconSecondDot"];
  }
  for (NSString *key in [files allKeys]) {
    UIImage *image;
    if (overrideTheme) {
      NSString *path = [%c(Neon) fullPathForImageNamed:key atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", overrideTheme]];
      if (path) image = [UIImage imageWithContentsOfFile:path];
    } else {
      for (NSString *theme in themes) {
        NSString *path = [%c(Neon) fullPathForImageNamed:key atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
        if (path) {
          image = [UIImage imageWithContentsOfFile:path];
          break;
        }
      }
    }
    if (!image) continue;
    const char *ivarName = [[@"_" stringByAppendingString:[files objectForKey:key]] cStringUsingEncoding:NSUTF8StringEncoding];
    MSHookIvar<CALayer *>(self, ivarName).backgroundColor = [UIColor clearColor].CGColor;
    MSHookIvar<CALayer *>(self, ivarName).contents = (id)[image CGImage];
  }
  return self;
}

%end

UIImage *customClockBackground(CGSize size, BOOL masked) {
  UIImage *custom;
  if (overrideTheme) {
    NSString *path = [%c(Neon) fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", overrideTheme]];
    if (path) custom = [UIImage imageWithContentsOfFile:path];
  } else {
    for (NSString *theme in themes) {
      NSString *path = [%c(Neon) fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
      if (path) {
        custom = [UIImage imageWithContentsOfFile:path];
        break;
      }
    }
  }
  if (!custom) return nil;
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  if (masked) CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), [%c(Neon) getMaskImage].CGImage);
  [custom drawInRect:CGRectMake(0, 0, size.width, size.height)];
  custom = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return custom;
}

%hook SBClockApplicationIconImageView

- (UIImage *)contentsImage {
  return customClockBackground(%orig.size, YES) ? : %orig;
}

- (UIImage *)squareContentsImage {
  return customClockBackground(%orig.size, NO) ? : %orig;
}

%end

// For rendering the static icon with arrows

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
  %orig;
  CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.artikus.neonboard"];
  [center runServerOnCurrentThread];
  [center registerForMessageName:@"renderClockIcon" target:self selector:@selector(renderClockIcon)];
}

%new
- (void)renderClockIcon {
  // update prefs first
  [%c(Neon) loadPrefs];
  overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobiletimer"];
  if (overrideTheme && [overrideTheme isEqualToString:@"none"]) return;
  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) themes = [%c(Neon) themes];
  // stuff
  SBClockApplicationIconImageView *view = [[%c(SBClockApplicationIconImageView) alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
  [view _setAnimating:NO];
  // these can be probably calculated via degrees but i'm lazy; i wish setOverrideDate existed on ios <13 :/
  [MSHookIvar<CALayer *>(view, "_hours") setAffineTransform:CGAffineTransformMake(0.577, -0.816, 0.816, 0.577, 0, 0)];
  [MSHookIvar<CALayer *>(view, "_minutes") setAffineTransform:CGAffineTransformMake(0.453, 0.891, -0.891, 0.453, 0, 0)];
  [MSHookIvar<CALayer *>(view, "_seconds") setAffineTransform:CGAffineTransformMakeRotation(M_PI)];
  // render stuff
  UIImage *background = [UIImage imageWithContentsOfFile:[%c(Neon) iconPathForBundleID:@"com.apple.mobiletimer"]];
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), NO, [UIScreen mainScreen].scale);
  [background drawInRect:CGRectMake(0, 0, 60, 60)];
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  // ugly path. i know. but on some versions springboard can't write to /Library/Themes :/
  [UIImagePNGRepresentation(finalImage) writeToFile:@"/var/mobile/Media/NeonStaticClockIcon.png" atomically:YES];
  UIGraphicsEndImageContext();
}

%end

%end

%ctor {
  if (kCFCoreFoundationVersionNumber < 847.20) return; // iOS 7 introduced live clock so
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobiletimer"];
  if (overrideTheme && [overrideTheme isEqualToString:@"none"]) return;

  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    themes = [%c(Neon) themes];
    %init(Themes);
  }
}
