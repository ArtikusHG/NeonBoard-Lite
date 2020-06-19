#include "CustomizationController.h"
#include <Preferences/PSSpecifier.h>

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation CustomizationController

- (NSArray *)specifiers {
	if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Customization" target:self];
	return _specifiers;
}

// thanks Julioverne
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
	[dict setObject:value forKey:[specifier propertyForKey:@"key"]];
	[dict writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] ? : [NSMutableDictionary dictionary];
	return dict[[specifier propertyForKey:@"key"]] ? : NO;
}

@end
