#include "Neon.h"
#import <spawn.h>
#import <signal.h>
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

// picker

@interface AltIconPickerController : UIViewController <UITableViewDelegate, UITableViewDataSource>
- (instancetype)initWithBundleID:(NSString *)bundleID;
@property (nonatomic, retain) NSString *bundleID;
@property (nonatomic, retain) NSArray *themes;
@property (nonatomic, retain) NSArray *themeNames;
@property (nonatomic, retain) NSArray *icons;
@end

@implementation AltIconPickerController

- (instancetype)initWithBundleID:(NSString *)bundleID {
  self = [super init];
  self.title = @"Select icon";
  self.bundleID = bundleID;

  NSMutableArray *mutableThemes = [NSMutableArray new];
  NSMutableArray *mutableThemeNames = [NSMutableArray new];
  NSMutableArray *mutableIcons = [NSMutableArray new];
  for (NSString *theme in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil]) {
    NSString *path = [%c(Neon) iconPathForBundleID:bundleID fromTheme:theme];
    if (path) {
      [mutableThemes addObject:theme];
      NSString *themeName = theme;
      if ([[themeName substringFromIndex:themeName.length - 6] isEqualToString:@".theme"]) themeName = [themeName substringToIndex:themeName.length - 6];
      [mutableThemeNames addObject:theme];
      [path writeToFile:@"/var/mobile/a" atomically:YES encoding:NSUTF8StringEncoding error:nil];
      UIImage *icon = [UIImage imageWithContentsOfFile:path] ? : [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
      UIGraphicsBeginImageContextWithOptions(CGSizeMake(60, 60), NO, [UIScreen mainScreen].scale);
      CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 60, 60), [%c(Neon) getMaskImage].CGImage);
      [icon drawInRect:CGRectMake(0, 0, 60, 60)];
      icon = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
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
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
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
    [self setOverrideTheme:[self.themeNames objectAtIndex:indexPath.row]];
  }];
  [alert addAction:cancelAction];
  [alert addAction:setAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setOverrideTheme:(NSString *)theme {
  NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
  NSMutableDictionary *overrideThemes = [[prefs objectForKey:@"overrideThemes"] mutableCopy] ? : [NSMutableDictionary new];
  [overrideThemes setObject:theme forKey:self.bundleID];
  [prefs setObject:overrideThemes forKey:@"overrideThemes"];
	[prefs writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Done!" message:@"Would you like to respring now?" preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self respring];
  }];
  [alert addAction:cancelAction];
  [alert addAction:respringAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)respring {
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
	pid_t pid;
	int status;
	const char *argv[] = {"killall", "-KILL", "iconservicesagent", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);

	pid_t pid1;
	int status1;
	const char *argv1[] = {"killall", "-9", "iconservicesagent", "SpringBoard", NULL};
	posix_spawn(&pid1, "/usr/bin/killall", NULL, NULL, (char* const*)argv1, NULL);
	waitpid(pid1, &status1, WEXITED);
}

@end

// hook

@interface SBIconImageView
@property (assign, getter = isJittering, nonatomic) BOOL jittering;
@end

@interface SBIcon
- (NSString *)applicationBundleID;
@end

@interface SBIconView
@property (nonatomic, retain) SBIcon *icon;
- (SBIconImageView *)_iconImageView;
@end

@interface SBIconController : UIViewController
+ (instancetype)sharedInstance;
@end

%hook SBIconView

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  %orig;
  UITouch *touch = [touches anyObject];
  if (touch.tapCount == 2 && [self _iconImageView].jittering) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    AltIconPickerController *picker = [[AltIconPickerController alloc] initWithBundleID:[self.icon applicationBundleID]];
    [[%c(SBIconController) sharedInstance] presentViewController:[[UINavigationController alloc] initWithRootViewController:picker] animated:YES completion:nil];
  }
}

%end

%ctor {
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;
}
