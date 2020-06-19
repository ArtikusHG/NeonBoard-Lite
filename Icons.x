#include "Neon.h"

@interface _LSBoundIconInfo
@property (nonatomic, copy) NSString *applicationIdentifier;
@end

%group Themes

%hook _LSBoundIconInfo

- (void)setResourcesDirectoryURL:(NSURL *)URL {
  NSString *path = [Neon iconPathForBundleID:self.applicationIdentifier];
  return (path) ? %orig([NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]) : %orig;
}

- (NSDictionary *)bundleIconsDictionary {
  NSString *path = [Neon iconPathForBundleID:[self applicationIdentifier]].lastPathComponent;
	return (path) ? @{ @"CFBundlePrimaryIcon" : @{ @"CFBundleIconFiles" : @[path] } } : %orig;
}

%end

%end

%ctor {
	if ([Neon themes] && [Neon themes].count > 0) %init(Themes);
}
