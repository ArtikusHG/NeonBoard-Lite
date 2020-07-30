#include "../Neon.h"
#include <sys/utsname.h>

NSArray *themes;
NSDictionary *prefs;
NSDictionary *overrideThemes;

@implementation Neon

+ (NSArray *)themes {
  return themes;
}

+ (NSDictionary *)prefs {
  return prefs;
}

+ (NSDictionary *)overrideThemes {
  return overrideThemes;
}

CFPropertyListRef MGCopyAnswer(CFStringRef property);

+ (NSNumber *)deviceScale {
  return (__bridge NSNumber *)MGCopyAnswer(CFSTR("main-screen-scale"));
}

+ (BOOL)deviceIsIpad {
  struct utsname systemInfo;
  uname(&systemInfo);
  return ([[NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] rangeOfString:@"iPad"].location != NSNotFound);
}

// Usage: fullPathForImageNamed:@"SBBadgeBG" atPath:@"/Library/Themes/Viola Badges.theme/Bundles/com.apple.springboard/" (last symbol of basePath should be a slash (/)!)
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath {
  if (!name || !basePath) return nil;
  NSMutableArray *potentialFilenames = [NSMutableArray new];
  [potentialFilenames addObject:[name stringByAppendingString:@"-large.png"]];
  NSString *device = ([self deviceIsIpad]) ? @"~ipad" : @"~iphone";
  NSInteger scale = [[self deviceScale] integerValue];
  // this is a mess, too. BUT:
  // first, it puts the filenames for the actual device's scale (lets assume, 2x).
  // then - for the LARGER scales (e.g. if we assume it's 2x, it will add 3x)
  // and lastly - for the SMALLER ones (e.g. if we assume it's 2x, it will add nothingx)
  // this is required because some themes provide, for example, only SBClockIconBackgroundSquare@2x..... but it's 300 x 300.
  // this is absolutely awful, but we gotta deal with that, so i had to make up this weird workaround with scales :/
  for (int i = scale - 1; i < 3; i++) {
    NSString *scaleString = [@[@"", @"@2x", @"@3x"] objectAtIndex:i];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, device, scaleString]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, scaleString, device]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, scaleString]];
    [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, device]];
  }
  if (scale >= 2) {
    for (int i = scale - 2; i >= 0; i--) {
      NSString *scaleString = [@[@"", @"@2x", @"@3x"] objectAtIndex:i];
      [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, device, scaleString]];
      [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@%@.png", name, scaleString, device]];
      [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, scaleString]];
      [potentialFilenames addObject:[NSString stringWithFormat:@"%@%@.png", name, device]];
    }
  }
  [potentialFilenames addObject:[name stringByAppendingString:@".png"]]; // yes, this format somehow exists
  for (NSString *filename in potentialFilenames) {
    NSString *fullFilename = [basePath stringByAppendingString:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilename isDirectory:nil]) return fullFilename;
  }
	return nil;
}

+ (NSString *)iconPathForBundleID:(NSString *)bundleID {
  if (!bundleID) return nil;
  if ([bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/NeonStaticClockIcon.png"]) {
      return @"/var/mobile/Media/NeonStaticClockIcon.png";
    }
  }
  NSString *overrideTheme = [overrideThemes objectForKey:bundleID];
  if (overrideTheme) {
    if ([overrideTheme isEqualToString:@"none"]) return nil;
    if ([overrideTheme rangeOfString:@"/"].location != NSNotFound) {
      NSString *theme = [overrideTheme pathComponents][0];
      NSString *app = [overrideTheme pathComponents][1];
      return [self iconPathForBundleID:app fromTheme:theme];
    }
    NSString *path = [self iconPathForBundleID:bundleID fromTheme:overrideTheme];
    if (path) return path;
  }
  for (NSString *theme in themes) {
    NSString *path = [Neon iconPathForBundleID:bundleID fromTheme:theme];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
      return path;
    }
  }
  return nil;
}

// Usage: iconPathForBundleID:@"com.saurik.Cydia" fromTheme:@"Viola.theme"
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme {
  // Protection against dumbasses (me)
  if (!bundleID || !theme) return nil;
  // Check if theme dir exists
  NSString *themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles/", theme];
  if (![[NSFileManager defaultManager] fileExistsAtPath:themeDir isDirectory:nil]) return nil;
	// Return filename (or nil)
  NSString *path = [Neon fullPathForImageNamed:bundleID atPath:themeDir];
  if (!path && [bundleID isEqualToString:@"com.apple.mobiletimer"]) {
    themeDir = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard/", theme];
    path = [Neon fullPathForImageNamed:@"ClockIconBackgroundSquare" atPath:themeDir];
  }
  return path;
}

UIImage *maskImage;

+ (UIImage *)getMaskImage {
  if (maskImage) return maskImage;
  NSBundle *mobileIconsBundle = [NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"];
  UIImage *image = [%c(UIImage) imageNamed:@"AppIconMask" inBundle:mobileIconsBundle];
  return image;
}

+ (void)loadPrefs {
  if (@available(iOS 11, *)) prefs = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"] error:nil];
  else prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"];
  if (!prefs) return;

  NSMutableArray *mutableThemes = [[prefs valueForKey:@"enabledThemes"] mutableCopy] ? : [NSMutableArray new];
  for (int i = mutableThemes.count - 1; i >= 0; i--) {
    NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles", [mutableThemes objectAtIndex:i]];
    NSString *path2 = [NSString stringWithFormat:@"/Library/Themes/%@/Bundles/com.apple.springboard", [mutableThemes objectAtIndex:i]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path] && ![[NSFileManager defaultManager] fileExistsAtPath:path2]) [mutableThemes removeObjectAtIndex:i];
  }
  if (mutableThemes.count > 0) {
    themes = [mutableThemes copy];
    overrideThemes = [prefs objectForKey:@"overrideThemes"];
  }
}

@end

%ctor {
  [Neon loadPrefs];
  if (!prefs || !themes) return;
}
