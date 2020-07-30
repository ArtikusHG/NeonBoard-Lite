#include <Preferences/PSSpecifier.h>
#include "../Neon.h"
#include "SelectThemeController.h"

@implementation SelectThemeController

@synthesize searchController;
@synthesize originalSpecifiers;

UIImage *iconForCellFromIcon(UIImage *icon) {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), NO, [UIScreen mainScreen].scale);
  CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 60, 60), [NSClassFromString(@"Neon") getMaskImage].CGImage);
  [icon drawInRect:CGRectMake(0, 0, 60, 60)];
  UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newIcon;
}

- (NSString *)title { return @"Select theme"; }

- (NSArray *)specifiers {
  if (!_specifiers) {
    // load NeonEngine just in case
    if (!NSClassFromString(@"Neon")) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
    if (!NSClassFromString(@"Neon")) return _specifiers;
    _specifiers = [NSMutableArray new];

    for (NSString *theme in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil]) {
      NSString *themePath = [NSString stringWithFormat:@"/Library/Themes/%@/IconBundles", theme];
      if ([[NSFileManager defaultManager] fileExistsAtPath:themePath]) {
        // we check if the only thing in IconBundles is Icon.png (or icon.png, same but lowercase), the one provided to be displayed in the pref bundle, but not an actual app icon, to avoid listing useless themes
        NSSet *contentsSet = [NSSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:themePath error:nil]];
        if ([contentsSet isEqualToSet:[NSSet setWithArray:@[@"Icon.png"]]] || [contentsSet isEqualToSet:[NSSet setWithArray:@[@"icon.png"]]]) continue;

        NSString *title = theme;
        if ([[title substringFromIndex:title.length - 6] isEqualToString:@".theme"]) title = [title substringToIndex:title.length - 6];
        PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:title target:self set:nil get:nil detail:NSClassFromString(@"SelectIconController") cell:PSLinkCell edit:nil];

        // this is turning into a mess and i can't stop that, so i decided to at least explain the logic
        // we look for the Icon.png of the theme. it (appears that it) can be: Icon.png, icon.png, IconBundles/Icon.png, IconBundles/icon.png
        // we add these paths to an array. then we insert the app icon's path if it exists at the 0 index, so that the app icon is being used above the Icon.png (e.g. if both app icon and Icon.png exist, app icon will be used)
        // then, we assign the icon to an UIImage. if it's an appIcon, we assign it to @"thisIcon" of specifier to load it in SelectIconController
        // and then, we add it to the specifier's icon anyway.
        // hopefully artikus from the future will understand this code (or, even better, it will never break and there will be no need to understand it again)
        // to future self: just in case, i'm sorry
        NSMutableArray *iconPaths = [@[
          [themePath stringByAppendingPathComponent:@"Icon.png"],
          [themePath stringByAppendingPathComponent:@"icon.png"],
          [[themePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Icon.png"],
          [[themePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"icon.png"]
        ] mutableCopy];
        NSString *appIconPath = [NSClassFromString(@"Neon") iconPathForBundleID:[self.specifier propertyForKey:@"appBundleID"] fromTheme:theme];
        if (appIconPath) [iconPaths insertObject:appIconPath atIndex:0];
        UIImage *icon;
        for (NSString *iconPath in iconPaths) if ((icon = [UIImage imageWithContentsOfFile:iconPath])) break;
        if (icon) {
          icon = iconForCellFromIcon(icon);
          if (appIconPath) [specifier setProperty:icon forKey:@"thisIcon"]; // pass the icon to avoid loading it again when picking for selected app and of selected app im very good at explaining ik
        } else {
          icon = [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
          icon = iconForCellFromIcon(icon);
        }
        [specifier setProperty:icon forKey:@"iconImage"];

        [specifier setProperty:[self.specifier propertyForKey:@"appBundleID"] forKey:@"appBundleID"];
        [specifier setProperty:theme forKey:@"themeName"];
        [specifier setProperty:themePath forKey:@"themePath"];
        [specifier setProperty:@70 forKey:@"height"];
        [_specifiers addObject:specifier];
      }
    }
    [_specifiers sortUsingComparator:^NSComparisonResult(PSSpecifier *a, PSSpecifier *b) {
      return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    // unthemed
    PSSpecifier *unthemed = [PSSpecifier preferenceSpecifierNamed:@"Unthemed / stock" target:self set:nil get:nil detail:NSClassFromString(@"SelectIconController") cell:PSLinkCell edit:nil];
    [unthemed setProperty:@"none" forKey:@"themeName"];
    [unthemed setProperty:[self.specifier propertyForKey:@"appBundleID"] forKey:@"appBundleID"];
    [unthemed setProperty:@70 forKey:@"height"];
    // icon
    UIImage *icon;
    LSApplicationProxy *proxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:[self.specifier propertyForKey:@"appBundleID"]];
    if (proxy) {
      NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
      NSArray *iconFiles = bundle.infoDictionary[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"] ? : bundle.infoDictionary[@"CFBundleIconFiles"];
      if (!iconFiles && bundle.infoDictionary[@"CFBundleIconFile"]) iconFiles = @[bundle.infoDictionary[@"CFBundleIconFile"]];
      if ([iconFiles isKindOfClass:[NSArray class]]) icon = [UIImage imageNamed:[iconFiles lastObject] inBundle:bundle];
      [[NSString stringWithFormat:@"%@",bundle] writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    if (!icon) icon = [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
    icon = iconForCellFromIcon(icon);
    [unthemed setProperty:icon forKey:@"iconImage"];
    [unthemed setProperty:icon forKey:@"thisIcon"];
    [_specifiers insertObject:unthemed atIndex:0];
    originalSpecifiers = [_specifiers mutableCopy];
  }
  return _specifiers;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  searchController = [UISearchController new];
  searchController.searchResultsUpdater = self;
  searchController.hidesNavigationBarDuringPresentation = NO;
  searchController.dimsBackgroundDuringPresentation = NO;
  searchController.searchBar.delegate = self;
  if (@available(iOS 11, *)) self.navigationItem.searchController = searchController;
  else self.table.tableHeaderView = searchController.searchBar;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)controller {
  NSString *text = controller.searchBar.text;
  if (text.length == 0) {
    self.specifiers = originalSpecifiers;
    return;
  }
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PSSpecifier *specifier, NSDictionary *bindings) {
    return [specifier.name.lowercaseString rangeOfString:text.lowercaseString].location != NSNotFound;
  }];
  self.specifiers = [[originalSpecifiers filteredArrayUsingPredicate:predicate] mutableCopy];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  self.specifiers = originalSpecifiers;
}

@end
