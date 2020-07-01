#include "Neon.h"

@interface SBClockApplicationIconImageView
- (UIImage *)contentsImage;
@end

NSArray *themes;

%group Themes

%hook SBClockApplicationIconImageView

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  NSMutableDictionary *files = [NSMutableDictionary dictionaryWithDictionary:@{
    @"ClockIconSecondHand" : @"seconds",
    @"ClockIconMinuteHand" : @"minutes",
    @"ClockIconHourHand" : @"hours",
    @"ClockIconBlackDot" : @"hourMinuteDot",
    @"ClockIconRedDot" : @"secondDot",
    @"ClockIconHourMinuteDot" : @"hourMinuteDot",
    @"ClockIconSecondDot" : @"secondDot"
  }];
  for (NSString *key in [files allKeys]) {
    UIImage *image;
    for (NSString *theme in themes) {
      NSString *path = [%c(Neon) fullPathForImageNamed:key atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
      if (path) {
        image = [UIImage imageWithContentsOfFile:path];
        break;
      }
    }
    if (!image) continue;
    const char *ivarName = [[@"_" stringByAppendingString:[files objectForKey:key]] cStringUsingEncoding:NSUTF8StringEncoding];
    MSHookIvar<CALayer *>(self, ivarName).contents = (id)[image CGImage];
  }
  return self;
}

%end

UIImage *customClockBackground(CGSize size, BOOL masked) {
  UIImage *custom;
  for (NSString *theme in themes) {
    NSString *path = [%c(Neon) fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:[NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme]];
    if (path) {
      custom = [UIImage imageWithContentsOfFile:path];
      break;
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

%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

	if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    themes = [%c(Neon) themes];
    %init(Themes);
  }
}
