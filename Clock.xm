#include "Neon.h"

@interface SBClockApplicationIconImageView
@end

@interface _UIAssetManager
@property (nonatomic, readonly) NSBundle *bundle;
+ (instancetype)assetManagerForBundle:(NSBundle *)bundle;
- (UIImage *)imageNamed:(NSString *)name;
@end

%hook SBClockApplicationIconImageView

NSArray *themes;

- (instancetype)initWithFrame:(CGRect)frame {
  self = %orig;
  NSMutableDictionary *files = [NSMutableDictionary dictionaryWithDictionary:@{
    @"ClockIconSecondHand" : @"seconds",
    @"ClockIconMinuteHand" : @"minutes",
    @"ClockIconHourHand" : @"hours",
    @"ClockIconBlackDot" : @"blackDot",
    @"ClockIconRedDot" : @"redDot",
    @"ClockIconBlackDot" : @"hourMinuteDot",
    @"ClockIconRedDot" : @"secondDot",
    @"ClockIconHourMinuteDot" : @"hourMinuteDot",
    @"ClockIconSecondDot" : @"secondDot"
  }];
  for (NSString *key in [files allKeys]) {
    _UIAssetManager *manager = [%c(_UIAssetManager) assetManagerForBundle:[NSBundle mainBundle]];
    UIImage *image = [manager imageNamed:key];
    if (!image) continue;
    const char *ivarName = [[@"_" stringByAppendingString:[files objectForKey:key]] cStringUsingEncoding:NSUTF8StringEncoding];
    MSHookIvar<CALayer *>(self, ivarName).contents = (id)[image CGImage];
  }
  return self;
}

%end

%hook _UIAssetManager

- (UIImage *)imageNamed:(NSString *)name configuration:(id)configuration cachingOptions:(id)cachingOptions attachCatalogImage:(BOOL)attachCatalogImage {
  if (name.length > 4 && [[name substringFromIndex:name.length - 4] isEqualToString:@".png"]) name = [name substringToIndex:name.length - 4];
  for (NSString *theme in themes) {
    NSBundle *bundle = self.bundle ? : [NSBundle mainBundle];
    NSString *imagePath = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/%@/", theme, [bundle bundleIdentifier]];
    NSString *path = [Neon fullPathForImageNamed:name atPath:imagePath];
    // use com.apple.springboard instead of com.apple.SpringBoardHome and such weird shits
    if (!path && [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
      imagePath = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
      path = [Neon fullPathForImageNamed:name atPath:imagePath];
    }
    if (path) return [UIImage imageWithContentsOfFile:path];
  }
  return %orig;
}

%end
