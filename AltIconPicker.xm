#include "Neon.h"
#import <spawn.h>
#import <signal.h>
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@interface SBIconController : UIViewController
+ (instancetype)sharedInstance;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) NSDictionary *iconsDictionary;
@end

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
- (NSMutableArray *)allInstalledApplications;
@end

@interface LSBundleProxy
+ (LSApplicationProxy *)bundleProxyForIdentifier:(NSString *)identifier;
@end

UIImage *unthemedIconForBundleID(NSString *bundleID) {
  LSApplicationProxy *proxy = [%c(LSBundleProxy) bundleProxyForIdentifier:bundleID];
  if (proxy) {
    // TODO _boundIconsDictionary (the LSLazy pepega)
    // also exclude apple weirdo apps
    NSArray *icons = [[proxy.iconsDictionary objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"];
    NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
    return [UIImage imageNamed:[icons lastObject] inBundle:bundle];
  }
  return [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
}

UIImage *iconForCellFromIcon(UIImage *icon) {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), NO, [UIScreen mainScreen].scale);
  CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 60, 60), [%c(Neon) getMaskImage].CGImage);
  [icon drawInRect:CGRectMake(0, 0, 60, 60)];
  UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newIcon;
}

@interface AltIconPickerController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
- (instancetype)initWithIconBundleID:(NSString *)iconBundleID appBundleID:(NSString *)appBundleID includeUnthemed:(BOOL)includeUnthemed;
@property (nonatomic, retain) NSString *appBundleID;
@property (nonatomic, retain) NSString *iconBundleID;
@property (nonatomic, retain) NSArray *themes;
@property (nonatomic, retain) NSArray *themeNames;
@property (nonatomic, retain) NSArray *icons;
@end

@implementation AltIconPickerController

- (instancetype)initWithIconBundleID:(NSString *)iconBundleID appBundleID:(NSString *)appBundleID includeUnthemed:(BOOL)includeUnthemed {
  self = [super init];
  self.title = @"Select icon";
  self.appBundleID = appBundleID;
  self.iconBundleID = iconBundleID;

  NSMutableArray *mutableThemes = [NSMutableArray new];
  NSMutableArray *mutableThemeNames = [NSMutableArray new];
  NSMutableArray *mutableIcons = [NSMutableArray new];

  // get unthemed icon
  if (includeUnthemed) {
    UIImage *stockIcon = iconForCellFromIcon(unthemedIconForBundleID(iconBundleID));
    [mutableIcons addObject:stockIcon];
    [mutableThemeNames addObject:@"Unthemed / stock"];
    [mutableThemes addObject:@"none"];
  }

  for (NSString *theme in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil]) {
    NSString *path = [%c(Neon) iconPathForBundleID:iconBundleID fromTheme:theme];
    if (path) {
      [mutableThemes addObject:theme];
      NSString *themeName = theme;
      if ([[themeName substringFromIndex:themeName.length - 6] isEqualToString:@".theme"]) themeName = [themeName substringToIndex:themeName.length - 6];
      [mutableThemeNames addObject:themeName];
      UIImage *icon = [UIImage imageWithContentsOfFile:path] ? : [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
      icon = iconForCellFromIcon(icon);
      [mutableIcons addObject:icon];
    }
  }
  self.themes = [mutableThemes copy];
  self.themeNames = [mutableThemeNames copy];
  self.icons = [mutableIcons copy];

  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.rowHeight = 70;
  [self.view addSubview:tableView];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];;
}

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.themeNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
  cell.textLabel.text = [self.themeNames objectAtIndex:indexPath.row];
  cell.imageView.image = [self.icons objectAtIndex:indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set icon?" message:@"The icon you've selected will be used instead of the default one" preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self setOverrideTheme:[self.themes objectAtIndex:indexPath.row]];
  }];
  [alert addAction:cancelAction];
  [alert addAction:setAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setOverrideTheme:(NSString *)theme {
  NSMutableDictionary *prefs;
  if (@available(iOS 11.0, *)) prefs = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
  else prefs = [[NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] mutableCopy] ? : [NSMutableDictionary dictionary];
  NSMutableDictionary *overrideThemes = [[prefs objectForKey:@"overrideThemes"] mutableCopy] ? : [NSMutableDictionary new];
  NSString *override = (![self.appBundleID isEqualToString:self.iconBundleID]) ? [NSString stringWithFormat:@"%@/%@", theme, self.iconBundleID] : theme;
  [overrideThemes setObject:override forKey:self.appBundleID];
  [prefs setObject:overrideThemes forKey:@"overrideThemes"];
  if (@available(iOS 11, *)) [prefs writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
  else [prefs writeToFile:@PLIST_PATH_Settings atomically:YES];

  if (@available(iOS 8.0, *)) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Done!" message:@"Would you like to respring now?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      [self respring];
    }];
    [alert addAction:cancelAction];
    [alert addAction:respringAction];
    [self presentViewController:alert animated:YES completion:nil];
  } else {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"Would you like to respring now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Respring", nil];
    alert.tag = 420;
    [alert show];
  }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    if (alertView.tag == 420) [self respring];
    else if (alertView.tag == 69) [self setOverrideTheme:[self.themes objectAtIndex:indexPath.row]];
  }
}

- (void)respring {
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
  [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/MappedImageCache/Persistent" error:nil];

  pid_t pid;
	int status;
  const char *argv[] = {"killall", "-KILL", "lsd", "lsdiconservice", "iconservicesagent", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);

	pid_t pid1;
	int status1;
	const char *argv1[] = {"killall", "-9", "iconservicesagent", "SpringBoard", NULL};
	posix_spawn(&pid1, "/usr/bin/killall", NULL, NULL, (char* const*)argv1, NULL);
	waitpid(pid1, &status1, WEXITED);
}

@end

@interface AppPickerController : UIViewController <UITableViewDelegate, UITableViewDataSource>
- (instancetype)initWithBundleID:(NSString *)bundleID;
@property (nonatomic, retain) NSArray *titles;
@property (nonatomic, retain) NSDictionary *icons;
@property (nonatomic, retain) NSDictionary *bundleIDs;
@property (nonatomic, retain) NSString *bundleID;
@end

@implementation AppPickerController

- (instancetype)initWithBundleID:(NSString *)bundleID {
  self = [super init];
  self.bundleID = bundleID;
  self.title = @"Select app";
  NSArray *apps = [[%c(LSApplicationWorkspace) defaultWorkspace] allInstalledApplications];
  NSMutableDictionary *mutableBundleIDs = [NSMutableDictionary new];
  NSMutableDictionary *mutableIcons = [NSMutableDictionary new];
  NSMutableArray *mutableTitles = [NSMutableArray new];
  for (LSApplicationProxy *proxy in apps) {
    NSBundle *bundle = [NSBundle bundleWithURL:proxy.bundleURL];
    NSString *title = [bundle.infoDictionary objectForKey:@"CFBundleDisplayName"] ? : [bundle.infoDictionary objectForKey:@"CFBundleName"] ? : proxy.applicationIdentifier;
    [mutableTitles addObject:title];
    [mutableBundleIDs setObject:proxy.applicationIdentifier forKey:title];
    [mutableIcons setObject:[UIImage _applicationIconImageForBundleIdentifier:proxy.applicationIdentifier format:2 scale:[UIScreen mainScreen].scale] forKey:title];
  }
  self.titles = [[mutableTitles copy] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
  self.bundleIDs = [mutableBundleIDs copy];
  self.icons = [mutableIcons copy];
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
  tableView.delegate = self;
  tableView.dataSource = self;
  [self.view addSubview:tableView];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
}

- (void)dismiss {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.bundleIDs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
  NSString *title = [self.titles objectAtIndex:indexPath.row];
  cell.textLabel.text = title;
  cell.detailTextLabel.text = [self.titles objectAtIndex:indexPath.row];
  cell.imageView.image = [self.icons objectForKey:title];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  AltIconPickerController *picker = [[AltIconPickerController alloc] initWithIconBundleID:[self.bundleIDs objectForKey:[self.titles objectAtIndex:indexPath.row]] appBundleID:self.bundleID includeUnthemed:NO];
  [self dismiss];
  [[%c(SBIconController) sharedInstance] presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
}

@end

// hook

@interface SBIcon : NSObject
- (NSString *)applicationBundleID;
@end

@interface SBIconView
@property (nonatomic, retain) SBIcon *icon;
@end

%hook SBIconView

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  %orig;
  UITouch *touch = [touches anyObject];
  if (touch.tapCount == 2) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select option" message:@"Select option to pick icon from:" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *allAppsAction = [UIAlertAction actionWithTitle:@"From all apps' icons" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      AppPickerController *picker = [[AppPickerController alloc] initWithBundleID:[self.icon applicationBundleID]];
      [[%c(SBIconController) sharedInstance] presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
    }];
    UIAlertAction *thisAppAction = [UIAlertAction actionWithTitle:@"From this app's icons" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
      AltIconPickerController *picker = [[AltIconPickerController alloc] initWithIconBundleID:[self.icon applicationBundleID] appBundleID:[self.icon applicationBundleID] includeUnthemed:YES];
      [[%c(SBIconController) sharedInstance] presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
    }];
    [alert addAction:cancelAction];
    [alert addAction:allAppsAction];
    [alert addAction:thisAppAction];
    [[%c(SBIconController) sharedInstance] presentViewController:alert animated:YES completion:nil];
  }
}

%end
