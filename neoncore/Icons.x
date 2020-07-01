#include "../Neon.h"

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

%group Themes

%hook _LSBoundIconInfo

- (void)setResourcesDirectoryURL:(NSURL *)URL {
  NSString *path = [%c(Neon) iconPathForBundleID:self.applicationIdentifier];
  return (path) ? %orig([NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]) : %orig;
}

- (NSDictionary *)bundleIconsDictionary {
  NSString *path = [%c(Neon) iconPathForBundleID:[self applicationIdentifier]].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%group GlyphMode

// Remove black bg
%hook ISIconCacheClient
- (NSData *)iconBitmapDataWithResourceLocator:(id)locator variant:(int)variant options:(int)options {
    return %orig(locator, variant, 8);
}
%end

// Remove table & app switcher icon outline
CGImageSourceRef CGImageSourceCreateWithURL(CFURLRef url, CFDictionaryRef options);

%hookf(CGImageSourceRef, CGImageSourceCreateWithURL, CFURLRef url, NSDictionary *options) {
  if ([[(__bridge NSURL *)url path] rangeOfString:@"TableIconOutline"].location != NSNotFound) return nil;
  //[[NSString stringWithFormat:@"%@\n%@", [NSString stringWithContentsOfFile:@"/var/mobile/a" encoding:NSUTF8StringEncoding error:nil], [(__bridge NSURL *)URL path]] writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
  return %orig;
}

%end

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
@property (nonatomic, readonly) NSArray *allInstalledApplications;
@end

%ctor {
    // avoid injecting into stuff other than what we need & all apps to solve memory issues (e.g. daemons constantly crashing)
    // not needed; first expression is wrong angway, checks for string while areay consists of LSApplicationProxy objects lmao im so dumb
    //if (![[[%c(LSApplicationWorkspace) defaultWorkspace] allInstalledApplications] containsObject:[NSBundle mainBundle].bundleIdentifier] && ![@[@"iconservicesagent", @"lsd", @"SpringBoard", @"AppPredictionWidget"] containsObject:[[NSProcessInfo processInfo] processName]]) return;

    if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
    if (!%c(Neon)) return;
    if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
        %init(Themes);
        if ([[%c(Neon) prefs] valueForKey:@"kGlyphMode"] && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue]) %init(GlyphMode);
    }
}
