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
	NSMutableDictionary *dict;
	if (@available(iOS 11.0, *)) dict = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
	else dict = [[NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] mutableCopy] ? : [NSMutableDictionary dictionary];
	[dict setObject:value forKey:[specifier propertyForKey:@"key"]];
	if (@available(iOS 11.0, *)) [dict writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
	else [dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *dict;
	if (@available(iOS 11.0, *)) dict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] ? : [NSMutableDictionary dictionary];
	else dict = [NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] ? : [NSMutableDictionary dictionary];
	return dict[[specifier propertyForKey:@"key"]] ? : NO;
}

@end
