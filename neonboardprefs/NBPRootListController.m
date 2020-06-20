#import <spawn.h>
#import <signal.h>
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

- (void)respring {
    [[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
	pid_t pid;
	int status;
	const char *argv[] = {"killall", "SpringBoard", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)argv, NULL);
	waitpid(pid, &status, WEXITED);
}

@end