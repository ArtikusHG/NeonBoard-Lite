// a mess, which works, however, fine.

#include <Preferences/PSSpecifier.h>
#include <Preferences/PSTableCell.h>
#include "../Neon.h"
#include "OverridesController.h"
#include "SelectIconController.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

UIImage *iconForCellFromIcon(UIImage *icon);
void respring();

@interface SelectIconCell : PSTableCell
@end

@implementation SelectIconCell
- (UILabel *)textLabel {
	UILabel *label = [super textLabel];
	label.textColor = [UIColor blackColor];
	label.highlightedTextColor = [UIColor blackColor];
	return label;
}
@end

@implementation SelectIconController


// top option somewhere idk should be the selected app's icon; then the other app's icons
// tableview too. but with search.
- (NSString *)title { return @"Select icon"; }

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [NSMutableArray new];
		if ([self.specifier propertyForKey:@"thisIcon"]) {
			[_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"This app's icon"]];
			PSSpecifier *thisIcon = [PSSpecifier preferenceSpecifierNamed:@"This app's icon" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
	    [thisIcon setProperty:[SelectIconCell class] forKey:@"cellClass"];
	    [thisIcon setProperty:[self.specifier propertyForKey:@"thisIcon"] forKey:@"iconImage"];
	    [thisIcon setProperty:[self.specifier propertyForKey:@"appBundleID"] forKey:@"iconBundleID"];
	    [thisIcon setProperty:@70 forKey:@"height"];
	    thisIcon.buttonAction = @selector(setOverride:);
			[_specifiers addObject:thisIcon];
		}
		if ([self.specifier propertyForKey:@"themePath"]) {
			[_specifiers addObject:[PSSpecifier groupSpecifierWithName:@"All icons from the pack"]];
			if ([self.specifier propertyForKey:@"thisIcon"] && !self.iconSpecifiers) {
				PSSpecifier *loadButton = [PSSpecifier preferenceSpecifierNamed:@"Load all icons" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
				loadButton.buttonAction = @selector(loadIcons:);
				[_specifiers addObject:loadButton];
			} else self.shouldAutoLoadIcons = YES;
		}
		self.originalSpecifiers = _specifiers;
	}
	if (self.iconSpecifiers.count != 0) [_specifiers addObjectsFromArray:self.iconSpecifiers];
  return _specifiers;
}

- (void)loadIcons:(id)sender {
	if (sender) {
		[_specifiers removeLastObject];
		[self.table reloadData];
	}
	NSMutableArray *bundleIDs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.specifier propertyForKey:@"themePath"] error:nil] mutableCopy];
	if (!bundleIDs || bundleIDs.count == 0) return;
	for (int i = bundleIDs.count - 1; i >= 0; i--) {
		NSString *file = bundleIDs[i];
		if (file.length < 5 || ![file.pathExtension isEqualToString:@"png"]) continue;
		file = [file stringByDeletingPathExtension];
		if (file.length > 6 && [[file substringFromIndex:file.length - 6] isEqualToString:@"-large"]) file = [file substringToIndex:file.length - 6];
		for (NSString *character in @[@"@", @"~"]) {
			NSRange range = [file rangeOfString:character options:NSBackwardsSearch];
			if (range.location != NSNotFound) file = [file substringToIndex:range.location];
		}
		[bundleIDs replaceObjectAtIndex:i withObject:file];
	}
	[bundleIDs setArray:[[NSSet setWithArray:bundleIDs] allObjects]];
	// load NeonEngine JUST IN CASE
	if (!NSClassFromString(@"Neon")) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
	if (!NSClassFromString(@"Neon")) return;
	id progressAlert;
	if (@available(iOS 8, *)) {
		progressAlert = [UIAlertController alertControllerWithTitle:@"Loading icons, be patient..." message:@"" preferredStyle:UIAlertControllerStyleAlert];
		[self presentViewController:progressAlert animated:YES completion:nil];
	} else {
		progressAlert = [[UIAlertView alloc] initWithTitle:@"Loading icons, be patient..." message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
		[progressAlert setMessage:[NSString stringWithFormat:@"Loading icon 0 of %lu...", (unsigned long)bundleIDs.count]];
		[progressAlert show];
	}
	self.iconSpecifiers = [NSMutableArray new];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSInteger done = 0;
		for (NSString *bundleID in bundleIDs) {
			PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:bundleID target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
			[specifier setProperty:NSClassFromString(@"SelectIconCell") forKey:@"cellClass"];
			[specifier setProperty:bundleID forKey:@"iconBundleID"];
			[specifier setProperty:@70 forKey:@"height"];
			specifier.buttonAction = @selector(setOverride:);
			// grab icon
			NSString *path = [NSClassFromString(@"Neon") iconPathForBundleID:bundleID fromTheme:[self.specifier propertyForKey:@"themeName"]];
			UIImage *icon = [UIImage imageWithContentsOfFile:path] ? : [UIImage imageNamed:@"DefaultIcon-60" inBundle:[NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"]];
			[specifier setProperty:iconForCellFromIcon(icon) forKey:@"iconImage"];
			[self.iconSpecifiers addObject:specifier];
			done++;
			dispatch_async(dispatch_get_main_queue(), ^{
      	[progressAlert setMessage:[NSString stringWithFormat:@"Loading icon %ld of %lu...", (long)done, (unsigned long)bundleIDs.count]];
      });
		}
		[_specifiers addObjectsFromArray:self.iconSpecifiers];
		self.originalSpecifiers = [_specifiers mutableCopy];
		dispatch_async(dispatch_get_main_queue(), ^{
			if (@available(iOS 8, *)) [self dismissViewControllerAnimated:YES completion:nil];
			else [progressAlert dismissWithClickedButtonIndex:-1 animated:YES];
			[self.table reloadData];
		});
	});
}

- (void)viewDidAppear:(BOOL)didAppear {
	[super viewDidAppear:didAppear];
	if (self.shouldAutoLoadIcons) [self loadIcons:nil];
}

- (void)showRespringAlert {
	if (@available(iOS 8, *)) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Done!" message:@"Would you like to respring now?" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			[[OverridesController sharedInstance] reloadSpecifiers];
		}];
		UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			respring();
		}];
		[alert addAction:cancelAction];
		[alert addAction:respringAction];
		[self presentViewController:alert animated:YES completion:nil];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done!" message:@"Would you like to respring now?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Respring", nil];
		alert.tag = 69;
		[alert show];
	}
}

// gotta love supporting ios 7, at least i can do alert.tag = 420
PSSpecifier *globalSender;

- (void)setOverride:(PSSpecifier *)sender {
	if (@available(iOS 8, *)) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Set icon?" message:@"The icon you've selected will be used instead of the default one." preferredStyle:UIAlertControllerStyleAlert];
	  UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"Set" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self actuallySetOverride:sender];
		}];
	  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
	  [alert addAction:setAction];
	  [self presentViewController:alert animated:YES completion:nil];
	} else {
		globalSender = sender;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Set icon?" message:@"The icon you've selected will be used instead of the default one." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Set", nil];
		alert.tag = 420;
		[alert show];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 69) {
		if (buttonIndex == alertView.cancelButtonIndex) [[OverridesController sharedInstance] reloadSpecifiers];
		else respring();
	}
	else if (alertView.tag == 420 && buttonIndex != alertView.cancelButtonIndex && globalSender) [self actuallySetOverride:globalSender];
}

- (void)actuallySetOverride:(PSSpecifier *)sender {
	NSMutableDictionary *prefs;
	if (@available(iOS 11.0, *)) prefs = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
	else prefs = [[NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] mutableCopy] ? : [NSMutableDictionary dictionary];
	NSMutableDictionary *overrideThemes = [[prefs objectForKey:@"overrideThemes"] mutableCopy] ? : [NSMutableDictionary new];
	NSString *appBundleID = [self.specifier propertyForKey:@"appBundleID"];
	NSString *iconBundleID = [sender propertyForKey:@"iconBundleID"];
	NSString *theme = [self.specifier propertyForKey:@"themeName"];
	NSString *override = (![appBundleID isEqualToString:iconBundleID]) ? [NSString stringWithFormat:@"%@/%@", theme, iconBundleID] : theme;
	[overrideThemes setObject:override forKey:appBundleID];
	[prefs setObject:overrideThemes forKey:@"overrideThemes"];
	if (@available(iOS 11, *)) [prefs writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
	else [prefs writeToFile:@PLIST_PATH_Settings atomically:YES];
	[self showRespringAlert];
}

@end
