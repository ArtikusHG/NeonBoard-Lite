#include "../Neon.h"

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

%group Themes

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

@interface LSBundleProxy : NSObject
@end

// dONT mind that beta code lmaoooo
// if someone knows why tf does it crash even when returning pure %orig tell me plz lol

//%hook LSBundleProxy

/*- (id)_initWithBundleUnit:(unsigned)bundleUnit context:(id)context bundleType:(unsigned long long)bundleType bundleID:(NSString *)bundleID localizedName:(NSString *)localizedName bundleContainerURL:(NSURL *)bundleContainerURL dataContainerURL:(NSURL *)dataContainerURL resourcesDirectoryURL:(NSURL *)resourcesDirectoryURL iconsDictionary:(NSDictionary *)iconsDictionary iconFileNames:(NSArray *)iconFileNames version:(id)version {
  //if (!bundleID) return %orig;
  //[%c(Neon) iconPathForBundleID:bundleID];
  //if (path) {
    //NSURL *newResourcesDirectoryURL = [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent];
    //iconsDictionary = @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path.lastPathComponent] }, @"CFBundleIconName" : path.lastPathComponent };
    //return %orig(bundleUnit, context, bundleType, bundleID, localizedName, bundleContainerURL, dataContainerURL, newResourcesDirectoryURL, iconsDictionary, iconFileNames, version);
  //}
  return %orig;
}*/

//%end

/*%hook LSResourceProxy

// btw who tf in apple thought a method name that's 560 characters long is a good idea
// 11
- (instancetype)_initWithLocalizedName:(NSString *)localizedName boundApplicationIdentifier:(NSString *)boundApplicationIdentifier boundContainerURL:(NSURL *)boundContainerURL dataContainerURL:(NSURL *)dataContainerURL boundResourcesDirectoryURL:(NSURL *)boundResourcesDirectoryURL boundIconsDictionary:(NSDictionary *)boundIconsDictionary boundIconCacheKey:(NSString *)boundIconCacheKey boundIconFileNames:(NSArray *)boundIconFileNames typeIconOwner:(id)typeIconOwner boundIconIsPrerendered:(BOOL)boundIconIsPrerendered boundIconIsBadge:(BOOL)boundIconIsBadge {
  NSString *path = [%c(Neon) iconPathForBundleID:boundApplicationIdentifier];
  if (path) {
    boundResourcesDirectoryURL = [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent];
    boundIconsDictionary = @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path.lastPathComponent] }, @"CFBundleIconName" : path.lastPathComponent };
  }
  return %orig;
}
// 8 - 10
//- (instancetype)_initWithLocalizedName:(id)arg1 boundApplicationIdentifier:(id)arg2 boundContainerURL:(id)arg3 dataContainerURL:(id)arg4 boundResourcesDirectoryURL:(id)arg5 boundIconsDictionary:(id)arg6 boundIconCacheKey:(id)arg7 boundIconFileNames:(id)arg8 typeOwner:(id)arg9 boundIconIsPrerendered:(BOOL)arg10 boundIconIsBadge:(BOOL)arg11 ;

%end*/

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
  return %orig;
}

%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  if ([%c(Neon) themes] && [%c(Neon) themes].count > 0) {
    %init(Themes);
    if ([[%c(Neon) prefs] valueForKey:@"kGlyphMode"] && [[[%c(Neon) prefs] valueForKey:@"kGlyphMode"] boolValue]) %init(GlyphMode);
  }
}
