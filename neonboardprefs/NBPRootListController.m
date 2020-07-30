#import <spawn.h>
#import <signal.h>
#include <Preferences/PSSpecifier.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#include "NBPRootListController.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation NBPRootListController

void respring() {
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Media/NeonStaticClockIcon.png" error:nil];
  CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"com.artikus.neonboard"];
  [center sendMessageAndReceiveReplyName:@"renderClockIcon" userInfo:nil];

	[[NSFileManager defaultManager] removeItemAtPath:@"/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/MappedImageCache/Persistent" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Library/Caches/com.apple.IconsCache" error:nil];

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

- (NSArray *)specifiers {
	if(![[NSFileManager defaultManager] fileExistsAtPath:@PLIST_PATH_Settings isDirectory:nil]) [[NSFileManager defaultManager] createFileAtPath:@PLIST_PATH_Settings contents:nil attributes:nil];
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)respring {
  respring();
}

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
	else dict = [NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] ? : [NSDictionary dictionary];
	return dict[[specifier propertyForKey:@"key"]] ? : NO;
}

@end
