#include <Preferences/PSSpecifier.h>
#include "../Neon.h"
#include "SelectAppController.h"

@implementation SelectAppController

- (NSString *)title { return @"Select app"; }

- (NSArray *)specifiers {
  if (!_specifiers) {
    // TODO: complete this list.
    NSArray *internalApps = [NSArray arrayWithContentsOfFile:@"/Library/PreferenceBundles/neonboardprefs.bundle/InternalApps.plist"];
    _specifiers = [NSMutableArray new];
    for (LSApplicationProxy *proxy in [[NSClassFromString(@"LSApplicationWorkspace") defaultWorkspace] allInstalledApplications]) {
      if ([internalApps containsObject:proxy.applicationIdentifier]) continue;
      NSString *title = proxy.localizedName;
      // old versions (e.g. ios 7 don't get localizedName as an empty string for some reason :/)
      if (!title || title.length == 0) {
        NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
        title = bundle.infoDictionary[@"CFBundleName"] ? : bundle.infoDictionary[@"CFBundleExecutable"];
      }
      PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:NSClassFromString(@"SelectThemeController") cell:PSLinkCell edit:nil];
      [specifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:proxy.applicationIdentifier format:0 scale:[UIScreen mainScreen].scale] forKey:@"iconImage"];
      [specifier setProperty:proxy.applicationIdentifier forKey:@"appBundleID"];
      [_specifiers addObject:specifier];
    }
    [_specifiers sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
      return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    self.originalSpecifiers = [_specifiers mutableCopy];
  }
  return _specifiers;
}

@end
