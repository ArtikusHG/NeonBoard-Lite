#include "NBPRootListController.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation NBPRootListController

- (NSArray *)specifiers {
	if(![[NSFileManager defaultManager] fileExistsAtPath:@PLIST_PATH_Settings isDirectory:nil]) [[NSFileManager defaultManager] createFileAtPath:@PLIST_PATH_Settings contents:nil attributes:nil];
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

@end
