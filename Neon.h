#include <dlfcn.h>

@interface UIImage (Private)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

@interface Neon : NSObject
+ (NSArray *)themes;
+ (NSDictionary *)prefs;
+ (NSDictionary *)overrideThemes;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme;
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath;
+ (UIImage *)getMaskImage;
@end
