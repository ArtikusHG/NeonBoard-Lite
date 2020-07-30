#include "../Neon.h"

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

%group Themes13

%hook _LSBoundIconInfo

// hooking setter makes icons in safari "open in app" banner blank
- (NSURL *)resourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self.applicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSDictionary *)bundleIconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.applicationIdentifier].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%group Themes_1112

%hook LSApplicationProxy

// ios 11 & 12
- (NSURL *)_boundResourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self._boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSDictionary *)iconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self._boundApplicationIdentifier].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%group ThemesOlder

%hook LSApplicationProxy

// ios 10
- (NSURL *)boundResourcesDirectoryURL {
  //[[NSString stringWithFormat:@"%@\n%@", [NSString stringWithContentsOfFile:@"/var/mobile/a" encoding:NSUTF8StringEncoding error:nil], self.boundApplicationIdentifier] writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

- (NSURL *)resourcesDirectoryURL {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier];
  return (path) ? [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent] : %orig;
}

// is actually _LSLazyPropertyList of same format but who cares lol it works
- (NSDictionary *)iconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] }, @"UIPrerenderedIcon" : @YES } : %orig;
}

- (NSDictionary *)boundIconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:self.boundApplicationIdentifier].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] }, @"UIPrerenderedIcon" : @YES } : %orig;
}

%end

%end

%group GlyphMode

// Remove black bg
// iOS 13+
%hook ISIconCacheClient
- (NSData *)iconBitmapDataWithResourceLocator:(id)locator variant:(int)variant options:(int)options {
  return %orig(locator, variant, 8);
}
%end

// iOS 10.3 - 12
%hook LSApplicationProxy

- (NSData *)iconDataForVariant:(int)variant preferredIconName:(NSString *)iconName withOptions:(int)options {
  return %orig(variant, iconName, 8);
}

%end

// Remove table & app switcher icon outline
CGImageSourceRef CGImageSourceCreateWithURL(CFURLRef url, CFDictionaryRef options);
%hookf(CGImageSourceRef, CGImageSourceCreateWithURL, CFURLRef url, NSDictionary *options) {
  if ([[(__bridge NSURL *)url path] rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  return %orig;
}

%end

%group GlyphModeLegacy
// iOS 7 - ????? maybe theres a better way on like 9 or at least <10.3 versions of 10?
%hook UIImage

+ (UIImage *)_iconForResourceProxy:(LSApplicationProxy *)proxy variant:(int)variant variantsScale:(CGFloat)scale {
  if (![%c(Neon) iconPathForBundleID:proxy.boundApplicationIdentifier]) return %orig;
  UIImage *icon = %orig(proxy, 25, scale);
  CGSize size = %orig.size;
  UIGraphicsBeginImageContextWithOptions(size, NO, scale);
  [icon drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return finalImage;
}

%end

%end

// iOS 7 - 9 are weird; the unmasked image remains unthemed somehow
%group UnmaskedFixup
%hook SBIconImageCrossfadeView
- (void)setMasksCorners:(BOOL)masksCorners {
  %orig(NO);
}
%end
%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Themes13);
    else if (kCFCoreFoundationVersionNumber >= 1443.00) %init(Themes_1112)
    else %init(ThemesOlder);
    if (kCFCoreFoundationVersionNumber < 1348.00) %init(UnmaskedFixup);
    if ([[%c(Neon) prefs] valueForKey:@"kGlyphMode"] && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue]) {
      %init(GlyphMode);
      // also check 3x (afaik from 9.x there exist super retina devices yes)
      if (kCFCoreFoundationVersionNumber <= 1348.22) %init(GlyphModeLegacy);
    }
  }
}
