#include <spawn.h>
#include <signal.h>
#include <AppSupport/CPDistributedMessagingCenter.h>
#include "../Neon.h"
#include "NBPShared.h"

NSDictionary *prefsDict() {
  if (@available(iOS 11, *)) return [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] ? : [NSDictionary dictionary];
  return [NSDictionary dictionaryWithContentsOfFile:@PLIST_PATH_Settings] ? : [NSDictionary dictionary];
}

void writePrefsDict(NSDictionary *dict) {
  if (@available(iOS 11, *)) [dict writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
  else [dict writeToFile:@PLIST_PATH_Settings atomically:YES];
}

UIImage *iconForCellFromIcon(UIImage *icon, CGSize size) {
  UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
  CGContextClipToMask(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, size.width, size.height), [NSClassFromString(@"Neon") getMaskImage].CGImage);
  [icon drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *newIcon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newIcon;
}

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